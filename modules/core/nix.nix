{ pkgs, username, ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        username
      ];
      auto-optimise-store = true;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      openssl
      stdenv.cc.cc
      zlib

      # Prebuilt Chromium-style browser (T3 Code's bundled browser) needs
      # these at runtime; it is a non-Nix binary resolved through nix-ld.
      alsa-lib # libasound
      at-spi2-core # libatk, libatk-bridge, libatspi
      dbus # libdbus-1
      expat # libexpat
      glib # libglib, libgobject, libgio
      libgbm # libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr # libnspr4
      nss # libnss3, libnssutil3
      systemd # libudev
    ];
  };
}
