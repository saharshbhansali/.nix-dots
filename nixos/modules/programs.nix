{ pkgs, nixpkgs, lib, config, ... }:

{

  programs = {

    # Shells
    zsh.enable = true;
    fish.enable = true;

    # GNOME settings
    dconf.enable = true;

  };

}
