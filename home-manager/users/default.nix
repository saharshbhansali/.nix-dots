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
    ../modules/hm-packages.nix
    ../modules/hm-programs.nix
    ../modules/hm-nixvim.nix
    ../modules/hm-shell.nix
    ../modules/hm-configs.nix
    ../modules/hm-devtools.nix
    ../modules/hm-nushell.nix
    ../modules/hm-cursor.nix
    ../modules/hm-gdm.nix
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
