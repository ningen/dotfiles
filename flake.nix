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
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      nix-darwin,
      neovim-nightly-overlay,
      hunk,
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
            overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
            config.allowUnfree = true;
            config.allowBroken = true;
          };
          extraSpecialArgs = { inherit inputs; };
          inherit modules;
        };
    in
    {
      apps = forAllSystems (
        system:
        let
          hm = "${inputs.home-manager.packages.${system}.home-manager}/bin/home-manager";
        in
        {
          update-lock = {
            type = "app";
            program = toString (
              nixpkgs.legacyPackages.${system}.writeShellScript "update-lock" ''
                exec nix flake update
              ''
            );
          };
          switch = {
            type = "app";
            program = toString (
              nixpkgs.legacyPackages.${system}.writeShellScript "switch" ''
                set -eu
                case "$(uname -s)" in
                  Darwin)
                    ${hm} switch --flake '.#ningen@ningen-mba.local'
                    exec sudo darwin-rebuild switch --flake .#ningen
                    ;;
                  Linux)
                    if ! grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null && [ -z "''${WSL_INTEROP:-}" ]; then
                      echo "switch must run on macOS or inside WSL" >&2
                      exit 1
                    fi
                    exec ${hm} switch --flake '.#ningen@wsl'
                    ;;
                  *)
                    echo "switch must run on macOS or inside WSL" >&2
                    exit 1
                    ;;
                esac
              ''
            );
          };
        }
      );

      homeConfigurations = {
        "ningen@ningen-mba.local" = mkHome {
          system = "aarch64-darwin";
          modules = [
            ./nix/hosts/common/home.nix
            ./nix/packages/dev-tools.nix
            ./nix/packages/docker-cli.nix
            ./nix/packages/language-servers.nix
            ./nix/packages/formatters.nix
            ./nix/packages/linters.nix
            ./nix/packages/node-packages.nix
          ];
        };
        "ningen@wsl" = mkHome {
          system = "x86_64-linux";
          modules = [
            ./nix/hosts/common/home.nix
            ./nix/hosts/wsl/home.nix
            ./nix/packages/dev-tools.nix
            ./nix/packages/language-servers.nix
            ./nix/packages/formatters.nix
            ./nix/packages/linters.nix
            ./nix/packages/node-packages.nix
          ];
        };
      };

      darwinConfigurations.ningen = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./nix/hosts/ningen-mba/macos.nix ];
      };
    };
}
