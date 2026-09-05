{
  nixpkgs,
  inputs,
  config,
  lib,
  pkgs,
  ...
} @ args: {
  home.stateVersion = "24.11";

  home.username = "${args.username}";
  home.homeDirectory = "/home/${args.username}";

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
    ../modules/hm-services.nix
    # Specific
    ../modules/hm-nvim.nix
    ../modules/hm-nushell.nix
    ../modules/hm-spicetify.nix
    # Feature
    ../modules/hm-gaming.nix
    ../modules/hm-networking.nix
    ## System environment configurations
    ../modules/hm-environment-variables.nix
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
}
