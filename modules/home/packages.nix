{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      # CLI tools.
      ripgrep
      fd
      eza
      jq
      yq
      tree
      unzip
      zip
      aoc-cli
      docfd
      lazydocker
      gtrash
      viu
      nitch
      openssl
      programmer-calculator
      streamlink
      td
      treefmt
      toipe
      ttyper
      valgrind
      xxd

      # System/user utilities that are useful without a desktop.
      htop
      ncdu
      killall
      man-pages
      xdg-utils
      onefetch
      ffmpeg-full

      # Terminal extras.
      cbonsai
      cmatrix
      pipes
      sl
      tty-clock

      (bat-extras.batgrep.overrideAttrs (_oldAttrs: {
        doCheck = false;
      }))

      # Password manager CLI only. The GUI package is intentionally excluded.
      _1password-cli

      # Modern CLI tools.
      tokei
      dust
      duf
      procs
      bottom
      tealdeer
      httpie
      doggo
      sd
      choose
      hyperfine
      glow
      nix-tree
      nix-diff
      comma

      # Custom CLI overlays (see overlays/).
      sidecar
    ]
    ++ lib.optionals (pkgs ? ffsend) [ ffsend ]
    ++ lib.optionals (pkgs ? proton-vpn-cli) [ proton-vpn-cli ]
    ++ lib.optionals (pkgs ? tdf) [ tdf ]
    ++ lib.optionals (pkgs ? woomer) [ woomer ];
}
