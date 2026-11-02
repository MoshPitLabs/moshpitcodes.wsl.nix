# Stdio (local process) MCP servers shared across the coding agents.
#
# Plain data like mcp-servers.nix, but kept separate: that file is url-only and
# every agent maps it straight to a remote-server entry, while a stdio server
# needs `command`/`args` and each agent spells those differently. Each agent
# module imports this and renders it into its own format.
#
# unity-mcp: the Unity MCP relay from the Unity Editor package
# com.unity.ai.assistant 2.0, which runs on the Windows host. The agents run in
# NixOS-WSL and reach it through WSL interop (modules/core/wsl.nix). The Unity
# Editor installs the relay to %USERPROFILE%\.unity\relay\relay_win.exe; Nix does
# not fetch or build it, so the path does not exist until the Editor has
# generated it. `--mcp` is required: it makes the relay act as an MCP server.
# https://docs.unity3d.com/Packages/com.unity.ai.assistant@2.0/manual/unity-mcp-get-started.html
#
# Security: this makes each agent spawn a Windows executable with your user's
# privileges, so the path is a fixed absolute path under your own Windows
# profile, never derived from input or PATH. The relay needs no credentials; a
# new client is gated by Unity itself (Project Settings > AI > Unity MCP >
# Pending Connections), so no token belongs in this file.
let
  # Windows account name; the relay lives under C:\Users\<windowsUser>.
  windowsUser = "moshpit";
in
{
  unity-mcp = {
    command = "/mnt/c/Users/${windowsUser}/.unity/relay/relay_win.exe";
    args = [ "--mcp" ];
  };
}
