{ pkgs, username, ... }:
{
  # Required for zsh to work as a login shell (users.users.<name>.shell below).
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.zsh;
    # Start the user systemd manager at boot (not on first login) so user
    # services like t3 are up whenever the distro is.
    linger = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
