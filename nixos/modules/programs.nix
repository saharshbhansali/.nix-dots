{ pkgs, nixpkgs, lib, config, ... }:

{

  ## Core programs
  programs.git.enable = true;

  # Other programs
  programs = {
    appimage.enable = true;
    appimage.binfmt = true;
  };

}
