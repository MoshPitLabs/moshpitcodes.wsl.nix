{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;
  mcpStdioServers = import ./mcp-stdio-servers.nix;
  otel = import ./otel.nix;

  # Codex config is TOML, and ~/.codex/config.toml is mutable state: it records
  # per-project `trust_level` decisions and TUI state as you use the CLI. Owning
  # it with Home Manager would wipe those and stop Codex writing new ones, so
  # the servers are injected as `-c` overrides instead. Codex speaks streamable
  # HTTP natively; `codex mcp login <name>` stores tokens in ~/.codex/auth.json,
  # not in config.toml.
  mcpArgs = lib.concatStringsSep " " (
    lib.mapAttrsToList (name: server: "-c 'mcp_servers.${name}.url=\"${server.url}\"'") mcpServers
    # Stdio servers: `-c` values are TOML, and a JSON string or string array is
    # valid TOML. escapeShellArg quotes the whole override for the wrapper.
    # Stdio servers run outside the Codex sandbox as the host user, so their
    # tools always require approval.
    ++ lib.concatLists (
      lib.mapAttrsToList (name: server: [
        "-c ${lib.escapeShellArg "mcp_servers.${name}.command=${builtins.toJSON server.command}"}"
        "-c ${lib.escapeShellArg "mcp_servers.${name}.args=${builtins.toJSON server.args}"}"
        "-c ${lib.escapeShellArg "mcp_servers.${name}.default_tools_approval_mode=\"prompt\""}"
      ]) mcpStdioServers
    )
  );

  # Telemetry (see otel.nix) is injected the same way, for the same reason:
  # events go to the collector's /v1/logs and metrics to /v1/metrics. Do not set
  # `[analytics] enabled = false` in config.toml — it also disables custom OTLP
  # metrics exporters.
  otelArgs = lib.concatStringsSep " " [
    "-c 'otel.environment=\"wsl\"'"
    "-c 'otel.log_user_prompt=false'"
    "-c 'otel.exporter={otlp-http={endpoint=\"${otel.endpoint}/v1/logs\",protocol=\"binary\"}}'"
    "-c 'otel.metrics_exporter={otlp-http={endpoint=\"${otel.endpoint}/v1/metrics\",protocol=\"binary\"}}'"
  ];

  # Sandbox: commands may write the working directory and /tmp, with no network;
  # anything else is an approval request. Injected as `-c` overrides like the
  # rest, since config.toml is mutable. T3 Code sets its own mode per thread.
  sandboxArgs = lib.concatStringsSep " " [
    "-c 'sandbox_mode=\"workspace-write\"'"
    "-c 'approval_policy=\"on-request\"'"
  ];

  # Codex prefers a bwrap on PATH over its bundled copy.
  codex = pkgs.writeShellScriptBin "codex" ''
    export PATH=${lib.makeBinPath [ pkgs.bubblewrap ]}:$PATH
    exec ${pkgs.nodejs}/bin/npx -y @openai/codex@latest ${mcpArgs} ${otelArgs} ${sandboxArgs} "$@"
  '';
in
{
  home.packages = [ codex ];

  home.file.".codex/.gitkeep".text = "";

  programs.zsh.shellAliases = {
    codex-setup = ''
      echo "Setting up Codex with Doppler..."
      export OPENAI_API_KEY=$(doppler secrets get OPENAI_API_KEY --plain)
      echo "OpenAI API key loaded from Doppler"
    '';
    codex-doppler = "doppler run -- codex";
  };
}
