{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    xremap.url = "github:xremap/nix-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      nix-darwin,
      nixos-hardware,
      xremap,
    }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      mkHome =
        { system, modules }:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.allowBroken = true;
          };
          extraSpecialArgs = { inherit inputs; };
          inherit modules;
        };
    in
    {
      apps = forAllSystems (system: {
        update = {
          type = "app";
          program = toString (
            nixpkgs.legacyPackages.${system}.writeShellScript "update-script" ''
              set -e
              echo "Updating flake..."
              nix flake update
              echo "Updating home-manager..."
              nix run nixpkgs#home-manager -- switch --flake .#ningen@$HOSTNAME
              if [[ "$(uname)" == "Darwin" ]]; then
                echo "Updating nix-darwin..."
                sudo darwin-rebuild switch --flake .#ningen
              fi
              echo "Update complete!"
            ''
          );
        };
      });

      homeConfigurations = {
        "ningen@ningen-mba.local" = mkHome {
          system = "aarch64-darwin";
          modules = [
            ./nix/hosts/common/home.nix
            ./nix/packages/dev-tools.nix
            ./nix/packages/language-servers.nix
            ./nix/packages/formatters.nix
            ./nix/packages/node-packages.nix
          ];
        };
        "ningen@DESKTOP-0DRJD1E" = mkHome {
          system = "x86_64-linux";
          modules = [
            ./nix/hosts/common/home.nix
            ./nix/packages/dev-tools.nix
            ./nix/packages/language-servers.nix
            ./nix/packages/formatters.nix
            ./nix/packages/node-packages.nix
          ];
        };
        "ningen@nixos" = mkHome {
          system = "x86_64-linux";
          modules = [
            ./nix/hosts/common/home.nix
            ./nix/packages/gui.nix
            ./nix/packages/dev-tools.nix
            ./nix/packages/language-servers.nix
            ./nix/packages/formatters.nix
            ./nix/packages/node-packages.nix
          ];
        };
      };

      nixosConfigurations = {
        myNixOS = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nix/hosts/nixos/configuration.nix
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

      darwinConfigurations.ningen = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./nix/hosts/ningen-mba/macos.nix ];
      };
    };
}
