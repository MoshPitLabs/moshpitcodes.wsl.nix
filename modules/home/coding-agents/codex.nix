{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;

  # Codex config is TOML, and ~/.codex/config.toml is mutable state: it records
  # per-project `trust_level` decisions and TUI state as you use the CLI. Owning
  # it with Home Manager would wipe those and stop Codex writing new ones, so
  # the servers are injected as `-c` overrides instead. Codex speaks streamable
  # HTTP natively; `codex mcp login <name>` stores tokens in ~/.codex/auth.json,
  # not in config.toml.
  mcpArgs = lib.concatStringsSep " " (
    lib.mapAttrsToList (name: server: "-c 'mcp_servers.${name}.url=\"${server.url}\"'") mcpServers
  );

  codex = pkgs.writeShellScriptBin "codex" ''
    exec ${pkgs.nodejs}/bin/npx -y @openai/codex@latest ${mcpArgs} "$@"
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
