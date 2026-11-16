# Global Agent Instructions

## Atlas: use CI for full-project validation

- On Atlas, do not run repository-wide, workspace-wide, or full-project typechecks or test suites locally. This includes `tsc`, `tsgo`, `tsc-rs`, and package-manager or task-runner commands that invoke them or run broad test suites.
- Use CI for these checks: push the relevant changes, wait for CI results for the current commit, inspect failures, and fix them. Do not substitute a local full check when CI is queued, slow, or failing.
- Do not launch duplicate or background validation processes while waiting for CI. If CI does not provide the required check, report that gap rather than launching it on Atlas.
- Small, targeted tests for the specific change are permitted; do not expand them into a full-project run. If a validation command's scope is unclear, inspect its script/configuration before running it.
- This restriction applies to Atlas and all agent worktrees on it, including child agents. Include it when delegating work. It does not apply to other machines or CI runners.

## MCP servers

- All MCP servers are connected through Executor MCP.
- Treat Executor MCP as the single MCP gateway and registry for tool access.
- Do not add or configure individual MCP servers directly in Codex, Claude Code, or project-local config unless explicitly requested.
- When an MCP tool or server appears unavailable, first inspect Executor MCP connectivity, auth, and routing before changing client-side MCP configuration.
- Prefer documenting new MCP wiring in agent-infra so Codex, Claude Code, T3 Code, and other agent surfaces stay aligned.

## Web pages

- Use `pnpm dlx browse` when you need to fetch web pages with JS or need a full browser.
