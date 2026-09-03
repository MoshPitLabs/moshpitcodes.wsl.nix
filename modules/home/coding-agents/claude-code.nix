# ANTHROPIC_API_KEY is injected by coding-agents/default.nix.
{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;

  claude = pkgs.writeShellScriptBin "claude" ''
    exec ${pkgs.nodejs}/bin/npx -y @anthropic-ai/claude-code@latest "$@"
  '';

  # Claude Code does not read `mcpServers` from settings.json, and its user
  # scope lives in ~/.claude.json — mutable state (auth, history, per-project
  # data) that Home Manager must not own. A plugin can declare MCP servers in a
  # plain .mcp.json, and any directory under ~/.claude/skills/ holding a
  # .claude-plugin/plugin.json manifest is loaded automatically: personal scope,
  # every project, no marketplace, no install step, no trust gate. That makes it
  # the one fully declarative global surface for MCP in Claude Code.
  pluginDir = ".claude/skills/mcp-servers";
in
{
  home = {
    packages = [ claude ];

    # No "model" key here: the file is a read-only nix-store symlink, so pinning
    # a model would permanently shadow the default chosen interactively via
    # /model. Deny rules must use the Tool(pattern) form to match anything.
    file = {
      ".claude/settings.json" = {
        force = true;
        text = builtins.toJSON {
          permissions = {
            allow = [
              "Read"
              "Write"
              "Edit"
              "Bash"
              "WebFetch"
              "WebSearch"
            ];
            deny = [
              "Read(**/.env)"
              "Read(**/.env.*)"
              "Read(**/secrets.nix)"
              "Read(**/credentials.json)"
              "Edit(**/.env)"
              "Edit(**/secrets.nix)"
              "Edit(**/credentials.json)"
            ];
          };
        };
      };

      "${pluginDir}/.claude-plugin/plugin.json".text = builtins.toJSON {
        name = "mcp-servers";
        description = "MCP servers declared by the NixOS configuration.";
        version = "1.0.0";
        author.name = "moshpitcodes";
      };

      "${pluginDir}/.mcp.json".text = builtins.toJSON {
        mcpServers = lib.mapAttrs (_: server: {
          type = "http";
          inherit (server) url;
        }) mcpServers;
      };
    };

    sessionVariables = {
      CLAUDE_CODE_DISABLE_ERROR_REPORTING = "1";
      CLAUDE_CODE_DISABLE_TELEMETRY = "1";
    };
  };

  programs.zsh.shellAliases = {
    claude-setup = ''
      echo "Setting up Claude Code with Doppler..."
      export ANTHROPIC_API_KEY=$(doppler secrets get ANTHROPIC_API_KEY --plain)
      echo "Anthropic API key loaded from Doppler"
    '';
    claude-doppler = "doppler run -- claude";
  };
}
