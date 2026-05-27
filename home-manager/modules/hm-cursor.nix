{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
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

  ## Set environment variables for X and Wayland cursor settings
  home.sessionVariables = {
    XCURSOR_THEME = "Catppuccin Mocha Mauve";
    XCURSOR_SIZE = "20";
    HYPRCURSOR_THEME = lib.mkForce "Catppuccin Mocha Mauve";
    HYPRCURSOR_SIZE = lib.mkForce "20";
  };
}
