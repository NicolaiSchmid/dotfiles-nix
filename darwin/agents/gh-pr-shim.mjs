#!/usr/bin/env node
// gh-pr-shim — a drop-in `gh` wrapper that intercepts ONLY t3code's per-branch
// PR-status call (`gh pr list --head <b> --json <fields>`) and answers it from a
// per-repo cache filled by a conditional REST GET of /pulls. Pure REST: it never
// touches the GraphQL pool, so it can't get wedged when GraphQL is exhausted.
//
// t3 fires these per-branch calls concurrently across a status sweep, all as
// separate processes. They share one on-disk per-repo cache (that's the batching:
// one repo-wide fetch serves every branch). No lock — writes are atomic (temp +
// rename) and idempotent, so concurrent refreshers can't corrupt the file.
// Conditional requests (If-None-Match) make idle sweeps free (304s don't count).
//
// Anything that isn't t3's exact status call — and any error — execs the real gh
// untouched, so the shim can never break t3.
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync, renameSync, mkdirSync, statSync, utimesSync } from "node:fs";
import { join } from "node:path";

const args = process.argv.slice(2);
const REAL_GH = process.env.GH_PR_SHIM_REAL_GH || "/run/current-system/sw/bin/gh";
const CACHE_DIR = join(process.env.HOME || "/tmp", ".cache", "gh-pr-shim");
const TTL_MS = 20_000; // serve without revalidating within this window
const KNOWN_FIELDS = new Set([
  "number","title","url","baseRefName","headRefName","state",
  "mergedAt","updatedAt","isCrossRepository","headRepository","headRepositoryOwner",
]);
// gh auth token via a login shell can come back colorized; force plain + strip.
const stripAnsi = (s) => (s || "").replace(/\x1b\[[0-9;]*m/g, "");

function dbg(msg) {
  if (!process.env.GH_PR_SHIM_DEBUG) return;
  try {
    mkdirSync(CACHE_DIR, { recursive: true });
    writeFileSync(join(CACHE_DIR, "debug.log"), `${new Date().toISOString()} pid=${process.pid} :: ${msg}\n`, { flag: "a" });
  } catch {}
}

function passthrough() {
  dbg(`PASSTHROUGH argv=${JSON.stringify(args)}`);
  const r = spawnSync(REAL_GH, args, { stdio: "inherit" });
  process.exit(r.status ?? 1);
}

function parseT3Call() {
  if (args[0] !== "pr" || args[1] !== "list") return null;
  const rest = args.slice(2);
  let head = null, json = null, state = "open"; // gh's default --state is open
  for (let i = 0; i < rest.length; i++) {
    if (rest[i] === "--head") head = rest[++i];
    else if (rest[i] === "--json") json = rest[++i];
    else if (rest[i] === "--state") state = rest[++i];
    else if (rest[i] === "-R" || rest[i] === "--repo") return null;
  }
  if (!head || !json) return null;
  if (json.split(",").some((f) => !KNOWN_FIELDS.has(f))) return null;
  return { head, state };
}

// Match gh's --state filter against our mapped uppercase state.
function stateMatches(prState, want) {
  if (want === "all") return true;
  if (want === "open") return prState === "OPEN";
  if (want === "merged") return prState === "MERGED";
  if (want === "closed") return prState === "CLOSED" || prState === "MERGED";
  return true;
}

const t3 = parseT3Call();
if (!t3) passthrough();

// Map a REST /pulls item to the exact shape `gh pr list --json <fields>` emits.
// All fields come straight from REST (node_id gives gh's GraphQL ids); the only
// gap is the owner *display name*, absent from the pulls payload — fall back to
// login (t3 keys off login anyway).
function mapPR(p) {
  const hr = p.head?.repo || null;
  return {
    number: p.number,
    title: p.title,
    url: p.html_url,
    baseRefName: p.base?.ref ?? null,
    headRefName: p.head?.ref ?? null,
    state: p.merged_at ? "MERGED" : String(p.state || "").toUpperCase(),
    mergedAt: p.merged_at ?? null,
    updatedAt: p.updated_at ?? null,
    isCrossRepository: !!(hr && p.base?.repo && hr.full_name !== p.base.repo.full_name),
    headRepository: hr ? { id: hr.node_id, name: hr.name, nameWithOwner: hr.full_name } : null,
    headRepositoryOwner: hr?.owner ? { id: hr.owner.node_id, name: hr.owner.login, login: hr.owner.login } : null,
  };
}

function readCache(f) { try { return JSON.parse(readFileSync(f, "utf8")); } catch { return null; } }
function ageMs(f) { try { return Date.now() - statSync(f).mtimeMs; } catch { return Infinity; } }
function atomicWrite(f, text) {
  const tmp = `${f}.${process.pid}.tmp`;
  writeFileSync(tmp, text);
  renameSync(tmp, f); // atomic on the same filesystem → no torn reads, no lock needed
}
function serve(list) {
  const out = (list || [])
    .filter((p) => p.headRefName === t3.head && stateMatches(p.state, t3.state))
    .slice(0, 20);
  dbg(`SERVE head=${t3.head} state=${t3.state} matched=${out.length} of ${(list || []).length}`);
  process.stdout.write(JSON.stringify(out));
  process.exit(0);
}

try {
  const remote = spawnSync("git", ["remote", "get-url", "origin"], { encoding: "utf8" }).stdout?.trim();
  const m = remote && remote.match(/github\.com[:/]([^/]+)\/(.+?)(?:\.git)?$/);
  if (!m) passthrough();
  const owner = m[1], repo = m[2];

  mkdirSync(CACHE_DIR, { recursive: true });
  const base = join(CACHE_DIR, `${owner}__${repo}`);
  const dataFile = base + ".json";
  const etagFile = base + ".etag";

  let cached = readCache(dataFile);
  if (cached && ageMs(dataFile) < TTL_MS) serve(cached); // fresh → no network

  // stale or missing → conditional REST refresh (pure REST, no GraphQL)
  const token = stripAnsi(spawnSync(REAL_GH, ["auth", "token"], { encoding: "utf8" }).stdout).trim();
  if (!token) { if (cached) serve(cached); else passthrough(); }

  const url = `https://api.github.com/repos/${owner}/${repo}/pulls?state=all&per_page=100`;
  const headers = { Authorization: `Bearer ${token}`, Accept: "application/vnd.github+json", "User-Agent": "gh-pr-shim", "X-GitHub-Api-Version": "2022-11-28" };
  const etag = existsSync(etagFile) ? readFileSync(etagFile, "utf8") : null;
  if (etag) headers["If-None-Match"] = etag;

  const resp = await fetch(url, { headers });
  if (resp.status === 304 && cached) {
    utimesSync(dataFile, new Date(), new Date()); // unchanged → restart TTL
    serve(cached);
  } else if (resp.status === 200) {
    const data = (await resp.json()).map(mapPR);
    atomicWrite(dataFile, JSON.stringify(data));
    const ne = resp.headers.get("etag");
    if (ne) atomicWrite(etagFile, ne);
    serve(data);
  }
  // any other status (rate-limited / auth / 5xx): serve stale if we have it
  if (cached) serve(cached);
  passthrough();
} catch {
  passthrough();
}
