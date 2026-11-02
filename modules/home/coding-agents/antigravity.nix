# Google Antigravity CLI (agy).
{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;

  # T3 Code pins the Antigravity ACP runtime at 1.4.1 (ANTIGRAVITY_RELEASE_VERSION).
  # 1.4.2-1.4.4 write skills/system/run-workflow/SKILL.md into every session
  # workspace; 1.4.5 is unreviewed by T3. Bump only when T3's pin moves.
  # Ships agy_acp_server.par and localharness_external in one bin/; keep them together.
  antigravityAcp =
    lib.throwIfNot (pkgs.antigravity-acp.version == "1.4.1")
      "antigravity-acp is ${pkgs.antigravity-acp.version}, expected 1.4.1: T3 Code pins 1.4.1 (ANTIGRAVITY_RELEASE_VERSION); 1.4.2-1.4.4 write skills/system/run-workflow/SKILL.md into every session workspace and 1.4.5 is unreviewed by T3. Bump this guard deliberately only when T3's pin moves."
      pkgs.antigravity-acp;
in
{
  home.packages = [
    pkgs.antigravity-cli
    antigravityAcp
  ];

  home.file.".gemini/config/mcp_config.json".text = builtins.toJSON {
    mcpServers = lib.mapAttrs (_: server: {
      serverUrl = server.url;
    }) mcpServers;
  };
}
