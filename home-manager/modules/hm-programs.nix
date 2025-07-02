{ config, lib, pkgs, inputs, ... }:

{

  # Since we do not install home-manager, you need to let home-manager
  # manage your shell, otherwise it will not be able to add its hooks
  # to your profile.
  programs.home-manager.enable = true;
  # programs.zsh.enable = true;


  ## Enable other programs
  programs.browserpass.enable = true;
  programs.ghostty.enable = true;
  programs.git.enable = true;

}
