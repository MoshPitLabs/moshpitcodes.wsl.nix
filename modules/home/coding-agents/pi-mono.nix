# Pi coding agent configuration
# Runs @earendil-works/pi-coding-agent (successor to @mariozechner/pi-coding-agent)
# via npx -y so it always resolves the latest release without a network fetch
# at activation time or a separate ~/.npm-global prefix. OPENAI_API_KEY is
# provided by coding-agents/default.nix.
{ pkgs, ... }:
let
  mcpServers = import ./mcp-servers.nix;

  pi = pkgs.writeShellScriptBin "pi" ''
    exec ${pkgs.nodejs}/bin/npx -y @earendil-works/pi-coding-agent@latest "$@"
  '';
in
{
  home = {
    packages = [ pi ];

    sessionVariables = {
      # Skip startup version check for faster launch
      PI_SKIP_VERSION_CHECK = "1";
    };

    # Pi config directory structure
    file.".pi/agent/.gitkeep".text = "";
    # Current Pi has built-in Streamable HTTP and OAuth support.
    file.".pi/agent/mcp.json".text = builtins.toJSON {
      inherit mcpServers;
    };
  };

  # Shell aliases
  programs.zsh.shellAliases = {
    pi-setup = ''
      echo "Setting up pi with Doppler..."
      export ANTHROPIC_API_KEY=$(doppler secrets get ANTHROPIC_API_KEY --plain)
      export OPENAI_API_KEY=$(doppler secrets get OPENAI_API_KEY --plain)
      echo "API keys loaded from Doppler"
    '';
    pi-doppler = "doppler run -- pi";
  };
}
