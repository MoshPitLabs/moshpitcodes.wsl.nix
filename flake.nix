{
  description = "MoshPitCodes NixOS WSL2 Configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sidecar = {
      url = "github:marcus/sidecar/v1.13.0";
      flake = false;
    };

    td = {
      url = "github:marcus/td/v0.65.0";
      flake = false;
    };

    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;

      validateSecrets =
        secrets:
        assert builtins.isAttrs secrets || throw "secrets.nix must return an attribute set";
        assert (secrets.username or null) != null || throw "secrets.nix must define 'username'";
        secrets;

      flakeRoot = builtins.getEnv "FLAKE_ROOT";
      pwdPath = builtins.getEnv "PWD";
      secretsPath =
        let
          basePath = if flakeRoot != "" then flakeRoot else pwdPath;
        in
        if basePath != "" then /. + basePath + "/secrets.nix" else null;

      customsecrets =
        if secretsPath != null && builtins.pathExists secretsPath then
          validateSecrets (import secretsPath)
        else if builtins.pathExists ./secrets.nix then
          validateSecrets (import ./secrets.nix)
        else
          throw ''
            secrets.nix not found.

            Copy secrets.nix.example to secrets.nix, fill in your values, and
            rebuild from the repo root with --impure (secrets.nix is git-ignored,
            so it is resolved via $PWD / $FLAKE_ROOT at evaluation time):

              cp secrets.nix.example secrets.nix
              sudo nixos-rebuild switch --flake .#wsl --impure
          '';

      overlays = import ./overlays { inherit inputs; };
    in
    {
      nixosConfigurations.wsl =
        let
          host = "wsl";
          system = "x86_64-linux";
          specialArgs = {
            inherit
              self
              inputs
              host
              customsecrets
              ;
            inherit (customsecrets) username;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/${host}
            home-manager.nixosModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = overlays;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = specialArgs;
                users.${customsecrets.username} = import ./modules/home;
              };
            }
          ];
        };

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "moshpitcodes-wsl-nix";
            packages = with pkgs; [
              git
              just
              nil
              nixfmt-rfc-style
            ];
          };
        }
      );

      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
