# ANTHROPIC_API_KEY / OPENROUTER_API_KEY are injected by coding-agents/default.nix.
{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;

  # opencode merges every config source rather than replacing, so OPENCODE_CONFIG
  # can point at an MCP-only file and config.json keeps owning model/theme. Set
  # in the wrapper rather than home.sessionVariables so it holds however opencode
  # is launched, and left overridable for one-off runs.
  opencode = pkgs.writeShellScriptBin "opencode" ''
    export OPENCODE_CONFIG="''${OPENCODE_CONFIG:-$HOME/.config/opencode/mcp.json}"
    exec ${pkgs.nodejs}/bin/npx -y opencode-ai@latest "$@"
  '';
in
{
  home.packages = [ opencode ];

  home.file = {
    ".config/opencode/.gitkeep".text = "";
    ".config/opencode/agents/.gitkeep".text = "";
    ".config/opencode/commands/.gitkeep".text = "";
    ".config/opencode/modes/.gitkeep".text = "";
    ".config/opencode/plugins/.gitkeep".text = "";
    ".config/opencode/skills/.gitkeep".text = "";
    ".config/opencode/themes/.gitkeep".text = "";
    ".config/opencode/tools/.gitkeep".text = "";

    ".config/opencode/config.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      model = "openrouter/openai/gpt-5.2";
      theme = "rosepine";
      autoupdate = false;
      watcher.ignore = [
        ".opencode/logs/**"
        ".opencode/data/**"
      ];
    };

    # Dedicated MCP config, merged in via OPENCODE_CONFIG. opencode speaks
    # streamable HTTP natively and handles the OAuth dance itself (dynamic
    # client registration), so no credentials belong here.
    ".config/opencode/mcp.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      mcp = lib.mapAttrs (_: server: {
        type = "remote";
        inherit (server) url;
        enabled = true;
      }) mcpServers;
    };
  };

  programs.zsh.shellAliases = {
    opencode-setup = ''
      echo "Setting up OpenCode with Doppler..."
      export ANTHROPIC_API_KEY=$(doppler secrets get ANTHROPIC_API_KEY --plain)
      export OPENROUTER_API_KEY=$(doppler secrets get OPENROUTER_API_KEY --plain)
      echo "API keys loaded from Doppler"
    '';
    opencode-doppler = "doppler run -- opencode";
  };
}
