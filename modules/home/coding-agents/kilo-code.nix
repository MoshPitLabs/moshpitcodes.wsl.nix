{ pkgs, lib, ... }:
let
  mcpServers = import ./mcp-servers.nix;

  kilo = pkgs.writeShellScriptBin "kilo" ''
    exec ${pkgs.nodejs}/bin/npx -y @kilocode/cli "$@"
  '';
in
{
  home = {
    packages = [ kilo ];
    file = {
      ".config/kilo/.gitkeep".text = "";
      ".config/kilo/kilo.json".text = builtins.toJSON {
        mcp = lib.mapAttrs (_: server: {
          type = "remote";
          inherit (server) url;
          enabled = true;
        }) mcpServers;
      };
    };
  };

  programs.zsh.shellAliases = {
    kilo-doppler = "doppler run -- kilo";
  };
}
