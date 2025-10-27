{ nixpkgs, inputs, config, lib, pkgs, ... }:
# let
#   nixvim = inputs.nixvim.legacyPackages.${pkgs.system};
# in
{

  home.stateVersion = "24.11";

  home.username = "saharsh";
  home.homeDirectory = "/home/saharsh";


  ## Starting user services via systemd
  systemd.user.startServices = true;


  ## Import modules
  imports = [
    ## Application installation
    # System
    ../modules/hm-packages.nix
    ../modules/hm-programs.nix
    ../modules/hm-flatpaks.nix
    ../modules/hm-devtools.nix
    # Specific
    ../modules/hm-nixvim.nix
    ../modules/hm-nushell.nix
    ../modules/hm-spicetify.nix
    # Feature
    ../modules/hm-gaming.nix
    ## Application configurations
    ../modules/hm-configs.nix
    ../modules/hm-shell.nix
    ## Desktop Environment configurations
    ../modules/hm-cursor.nix
    ../modules/hm-gdm.nix
    ## Miscellaneous configurations
    ../modules/hm-desktop-shortcuts.nix
  ];


  ## Configure home-manager
  # home-manager.backupFileExtension = "hm.bak";


  ## Set environment variables for X and Wayland cursor settings
  home.sessionVariables = {
    EDITOR = "nvim";

    XCURSOR_THEME = "Catppuccin Mocha Mauve";
    XCURSOR_SIZE = "20";
    HYPRCURSOR_THEME = lib.mkForce "Catppuccin Mocha Mauve";
    HYPRCURSOR_SIZE = lib.mkForce "20";

    # QT_QPA_PLATFORMTHEME="kvantum";
  };

}
