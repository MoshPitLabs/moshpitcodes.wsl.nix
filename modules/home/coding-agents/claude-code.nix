# ANTHROPIC_API_KEY is injected by coding-agents/default.nix.
{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;
  otel = import ./otel.nix;

  # bubblewrap and socat must be on PATH for Claude Code's sandbox (the
  # `sandbox` block in settings.json below); nix does not put them there.
  claude = pkgs.writeShellScriptBin "claude" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.bubblewrap
        pkgs.socat
      ]
    }:$PATH
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

  # Status line for every project: [agent ·] model | repo:branch* or path | context | cost | +/- lines.
  statusline = pkgs.writeShellScript "claude-statusline" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.jq
        pkgs.git
        pkgs.coreutils
      ]
    }:$PATH
    ${builtins.readFile ./claude-statusline.sh}
  '';
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
          # Bash runs inside bubblewrap and is auto-approved while confined.
          # allowUnsandboxedCommands keeps the escape hatch for commands that
          # cannot run confined; using it still goes through a permission prompt.
          sandbox = {
            enabled = true;
            autoAllowBashIfSandboxed = true;
            allowUnsandboxedCommands = true;
          };
          statusLine = {
            type = "command";
            command = "${statusline}";
            padding = 0;
          };
          # OpenTelemetry -> infra-01 (see otel.nix). Session and account labels
          # are off to keep Prometheus cardinality flat; the collector sums the
          # delta counters. CLAUDE_CODE_DISABLE_TELEMETRY (below) only opts out
          # of Anthropic's own telemetry and does not affect OTLP export.
          env = {
            CLAUDE_CODE_ENABLE_TELEMETRY = "1";
            OTEL_METRICS_EXPORTER = "otlp";
            OTEL_LOGS_EXPORTER = "otlp";
            OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
            OTEL_EXPORTER_OTLP_ENDPOINT = otel.endpoint;
            OTEL_RESOURCE_ATTRIBUTES = "host.name=${otel.hostName}";
            OTEL_METRICS_INCLUDE_SESSION_ID = "false";
            OTEL_METRICS_INCLUDE_ACCOUNT_UUID = "false";
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
