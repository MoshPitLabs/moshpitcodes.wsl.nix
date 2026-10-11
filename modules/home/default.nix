{
  username,
  host,
  ...
}:
{
  imports = [
    ./bat.nix
    ./btop.nix
    ./coding-agents
    ./backup-repos.nix
    ./dev.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./language-servers.nix
    ./lazygit.nix
    ./nvim.nix
    ./packages.nix
    ./shell.nix
    ./ssh.nix
    ./theme.nix
    ./tmux.nix
    ./yazi.nix
    ./zsh
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
    # Non-Nix tool installs (e.g. the Kiro native installer) land here.
    sessionPath = [ "$HOME/.local/bin" ];
  };

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_CONFIG_HOST = host;
  };
}
