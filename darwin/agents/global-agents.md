# Global Agent Instructions

## MCP servers

- All MCP servers are connected through Executor MCP.
- Treat Executor MCP as the single MCP gateway and registry for tool access.
- Do not add or configure individual MCP servers directly in Codex, Claude Code, or project-local config unless explicitly requested.
- When an MCP tool or server appears unavailable, first inspect Executor MCP connectivity, auth, and routing before changing client-side MCP configuration.
- Prefer documenting new MCP wiring in agent-infra so Codex, Claude Code, T3 Code, and other agent surfaces stay aligned.
