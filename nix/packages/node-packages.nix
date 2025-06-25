{ pkgs, ... }: 
let
  nodePkgs = pkgs.callPackage ../../node2nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    nodePkgs."@anthropic-ai/claude-code"
    nodePkgs."@google/gemini-cli"
  ];
}
