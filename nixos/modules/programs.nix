{ pkgs, nixpkgs, lib, config, ... }:

{

  ## Core programs
  # git
  programs.git.enable = true;

  # nix-ld - to run unpatched binaries
  programs.nix-ld.enable = true;

  ## Other programs
  # KDE connect
  programs.kdeconnect.enable = true;

}
