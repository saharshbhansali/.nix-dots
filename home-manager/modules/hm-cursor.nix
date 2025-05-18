{ config, lib, pkgs, inputs, ... }:

{

  ## Set cursor configuration and theme in home-manager
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
    hyprcursor.size = 20;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 20;
  };

}
