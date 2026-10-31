# Google Antigravity CLI (agy).
{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;
in
{
  home.packages = [ pkgs.antigravity-cli ];

  home.file.".gemini/config/mcp_config.json".text = builtins.toJSON {
    mcpServers = lib.mapAttrs (_: server: {
      serverUrl = server.url;
    }) mcpServers;
  };
}
