# T3 Code - minimal web GUI that drives existing CLI coding agents
# (Codex, Claude Code, OpenCode). It is not itself an agent and has no API key
# of its own; it wraps the agents already provided by this directory, which
# pick up their keys from the environment (secrets.nix or Doppler).
# Runs via npx -y so it always resolves the latest release without a network
# fetch at activation time. `t3` serves a web UI on http://localhost:3773
# (opens fine in the Windows browser under WSL). A systemd user service keeps
# the server running in the background (t3-status / t3-logs / t3-restart).
# https://github.com/pingdotgg/t3code
{ lib, pkgs, ... }:
let
  t3 = pkgs.writeShellScriptBin "t3" ''
    exec ${pkgs.nodejs}/bin/npx -y t3@latest "$@"
  '';
in
{
  home.packages = [ t3 ];

  # `serve` is the headless variant of `start`: it never tries to open a browser.
  # systemd user services get a minimal PATH, so list where the agents t3 drives
  # live (claude installs to ~/.local/bin; the rest come from the user profile).
  # Keys are not injected here: for Doppler-provided keys stop the service and
  # use `t3-doppler` instead (both bind port 3773).
  systemd.user.services.t3 = {
    Unit = {
      Description = "T3 Code server";
      After = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${t3}/bin/t3 serve";
      Environment = "PATH=${
        lib.makeBinPath [
          pkgs.nodejs
          pkgs.git
          pkgs.bash
          pkgs.coreutils
        ]
      }:%h/.local/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin";
      Restart = "on-failure";
      RestartSec = "10s";
    };

    Install.WantedBy = [ "default.target" ];
  };

  programs.zsh.shellAliases = {
    # Launch with Doppler-provided keys so the agents t3 drives inherit them.
    t3-doppler = "doppler run -- t3";
    t3-status = "systemctl --user status t3.service";
    t3-logs = "journalctl --user -u t3.service -f";
    t3-restart = "systemctl --user restart t3.service";
  };
}
