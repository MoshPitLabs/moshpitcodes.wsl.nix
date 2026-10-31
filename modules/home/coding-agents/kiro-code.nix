# Kiro IDE/CLI configuration
# Uses the official native installer (https://cli.kiro.dev/install) instead of
# nixpkgs, so Kiro can auto-update itself in the background.
# ANTHROPIC_API_KEY is injected by coding-agents/default.nix; the install
# target ~/.local/bin is on PATH via home.sessionPath (modules/home/default.nix).
{
  pkgs,
  lib,
  ...
}:
let
  mcpServers = import ./mcp-servers.nix;
in
{
  home.file.".kiro/settings/mcp.json".text = builtins.toJSON {
    mcpServers = lib.mapAttrs (_: server: {
      inherit (server) url;
      disabled = false;
    }) mcpServers;
  };

  # Install Kiro CLI via native installer if not already present.
  # Current upstream installer places binaries in ~/.local/bin.
  # We inject Nix store paths into PATH so the installer script can
  # find curl, sha256sum, chmod, etc.
  home.activation.installKiro = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${
      lib.makeBinPath (
        with pkgs;
        [
          curl
          coreutils
          bash
          gnutar
          gzip
          unzip
        ]
      )
    }:$PATH"

    if [ -x "$HOME/.local/bin/kiro-cli" ] || [ -x "$HOME/.local/bin/kiro" ] || [ -x "$HOME/.kiro/bin/kiro" ]; then
      echo "Kiro already installed, skipping native installer"
    else
      echo "Installing Kiro via native installer..."
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL https://cli.kiro.dev/install -o /tmp/kiro-install.sh \
        && $DRY_RUN_CMD ${pkgs.bash}/bin/bash /tmp/kiro-install.sh \
        || echo "WARNING: Kiro installer failed (offline or installer error). It will retry on the next rebuild."
      rm -f /tmp/kiro-install.sh
    fi

    if [ -x "$HOME/.local/bin/kiro-cli" ]; then
      $DRY_RUN_CMD ln -sf "$HOME/.local/bin/kiro-cli" "$HOME/.local/bin/kiro"
    fi
  '';

  # Shell aliases
  programs.zsh.shellAliases = {
    kiro-doppler = "doppler run -- kiro";
  };
}
