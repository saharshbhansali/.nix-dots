{ config, lib, pkgs, inputs, ... }:

{

  programs = {
    # Shells
    zsh.enable = true;
    # fish.enable = true;
    # starship.enable = true;
    direnv = {
      enable = true;
      # enableBashIntegration = true; # see note on other shells below
      # enableZshIntegration = true; # see note on other shells below
      # enableFishIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
  };

}
