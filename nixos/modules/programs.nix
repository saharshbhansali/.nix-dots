{ pkgs, nixpkgs, lib, config, ... }:

{

  ## Core programs
  programs.git.enable = true;

  ## AppImages
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  ## Other programs

}
