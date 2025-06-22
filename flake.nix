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
    xremap.url = "github:xremap/nix-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      nix-darwin,
      xremap,
    }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
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
                sudo nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch  --flake .#ningen
              fi
              echo "Update complete!"
            ''
          );
        };
      });

      homeConfigurations = {
        # macOS configuration
        "ningen@ningen-mba.local" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home.nix
          ];
        };

        # Linux configuration
        "ningen@DESKTOP-0DRJD1E" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home.nix
          ];
        };

        "ningen@nixos" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home.nix
            ./gui.nix
          ];
        };

      };

      nixosConfigurations = {
        myNixOS = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

      darwinConfigurations.ningen = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./macos.nix ];
      };
    };
}
