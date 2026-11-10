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
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
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
      hunk,
      stylix,
      lanzaboote,
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
      apps = forAllSystems (
        system:
        let
          nh = "${nixpkgs.legacyPackages.${system}.nh}/bin/nh";
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
                    ${nh} home switch . -c 'ningen@ningen-mba.local' -d always
                    exec ${nh} darwin switch . -H ningen -d always
                    ;;
                  Linux)
                    if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null || [ -n "''${WSL_INTEROP:-}" ]; then
                      exec ${nh} home switch . -c 'ningen@wsl' -d always
                    fi
                    exec ${nh} os switch . -d always
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
            stylix.homeModules.stylix
            ./nix/hosts/common/stylix.nix
            ./nix/hosts/common/stylix-targets.nix
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
            stylix.homeModules.stylix
            ./nix/hosts/common/stylix.nix
            ./nix/hosts/common/stylix-targets.nix
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

      nixosConfigurations."ningen-desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          stylix.nixosModules.stylix
          lanzaboote.nixosModules.lanzaboote
          ./nix/hosts/common/stylix.nix
          ./nix/hosts/linux/hardware.nix
          ./nix/hosts/linux/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.ningen.imports = [
              ./nix/hosts/common/stylix.nix
              ./nix/hosts/common/stylix-targets.nix
              ./nix/hosts/common/home.nix
              ./nix/hosts/linux/hyprland.nix
              ./nix/hosts/linux/hyprlock.nix
              ./nix/hosts/linux/waybar.nix
              ./nix/hosts/linux/quickshell.nix
              ./nix/hosts/linux/rofi.nix
              ./nix/hosts/linux/migration.nix
              ./nix/hosts/linux/home.nix
              ./nix/packages/dev-tools.nix
              ./nix/packages/language-servers.nix
              ./nix/packages/formatters.nix
              ./nix/packages/linters.nix
              ./nix/packages/node-packages.nix
            ];
          }
        ];
      };

      darwinConfigurations.ningen = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./nix/hosts/ningen-mba/macos.nix ];
      };
    };
}
