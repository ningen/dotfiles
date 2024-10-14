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
  };
  

  outputs = { self, nixpkgs, home-manager, flake-utils, nix-darwin }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      apps.${system}.update = {
        type = "app";
        program = toString (pkgs.writeShellScript "update-script" ''
          set -e
          echo "Updating flake..."
          nix flake update
          echo "Updating home-manager..."
          nix run nixpkgs#home-manager -- switch --flake .#ningen@ningen-mba.local
          echo "Updating nix-darwin..."
          nix run nix-darwin -- switch --flake .#ningen
          echo "Update complete!"
        '');
      };
      homeConfigurations = {
        "ningen@ningen-mba.local" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
	    system = system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home.nix
          ];
        };
      };

      darwinConfigurations.ningen = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [ ./macos.nix ];
      };
    };
}
