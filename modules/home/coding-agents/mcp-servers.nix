# Single source of truth for MCP servers shared across the coding agents.
#
# This is plain data, not a Home Manager module — each agent module imports it
# and renders it into that agent's own config format, so a server is declared
# once here rather than repeated per agent.
#
# Auth: these servers use OAuth 2.1 with dynamic client registration, so no
# credentials belong in this file. The Nix store is world-readable, and anything
# interpolated into it is readable by every user on the machine. Each agent needs
# a one-time interactive login instead (see docs/configuration.md).
{
  linear = {
    url = "https://mcp.linear.app/mcp";
  };
}
