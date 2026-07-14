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
      mkNixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nix/hosts/nixos/configuration.nix
        ];
        specialArgs = {
          inherit inputs;
        };
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
          switch-wsl = {
            type = "app";
            program = toString (
              nixpkgs.legacyPackages.${system}.writeShellScript "switch-wsl" ''
                set -eu
                if [ "$(uname -s)" != Linux ] || { ! grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null && [ -z "''${WSL_INTEROP:-}" ]; }; then
                  echo "switch-wsl must run inside WSL" >&2
                  exit 1
                fi
                exec ${hm} switch --flake '.#ningen@wsl'
              ''
            );
          };
          switch-macos = {
            type = "app";
            program = toString (
              nixpkgs.legacyPackages.${system}.writeShellScript "switch-macos" ''
                set -eu
                if [ "$(uname -s)" != Darwin ]; then
                  echo "switch-macos must run on macOS" >&2
                  exit 1
                fi
                ${hm} switch --flake '.#ningen@ningen-mba.local'
                exec sudo darwin-rebuild switch --flake .#ningen
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
            ./nix/hosts/ningen-mba/home.nix
            ./nix/packages/dev-tools.nix
            ./nix/packages/docker-cli.nix
            ./nix/packages/language-servers.nix
            ./nix/packages/formatters.nix
            ./nix/packages/linters.nix
            ./nix/packages/node-packages.nix
          ];
        };
        "ningen@DESKTOP-3TRFQRS" = mkHome {
          system = "x86_64-linux";
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
        "ningen@nixos" = mkHome {
          system = "x86_64-linux";
          modules = [
            ./nix/hosts/common/home.nix
            ./nix/hosts/nixos/home.nix
            ./nix/packages/gui.nix
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

      nixosConfigurations = {
        myNixOS = mkNixos;
        nixos = mkNixos;
      };

      darwinConfigurations.ningen = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./nix/hosts/ningen-mba/macos.nix ];
      };
    };
}
