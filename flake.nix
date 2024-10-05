{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };
  

  outputs = { self, nixpkgs, home-manager, flake-utils }@inputs:
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
    };
}
