{
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: {
  environment.systemPackages = with pkgs; [
    nixd
    alejandra
    nixfmt
    nixfmt-tree
    nixpkgs-fmt
  ];

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
