{ config, lib, pkgs, inputs, ... }:

{

  system.stateVersion = "24.11";

  ## Nix settings

  # System settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # # Trusted-users list
  nix.settings.trusted-users = [ "root" "saharsh" ];

  # Extra options
  nix.extraOptions = ''
    # Add cachix binary caches
    extra-substituters = https://devenv.cachix.org
    extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
  '';


  ## Package/module imports

  imports = [
    ## System configuration
    ../modules/boot.nix
    ../modules/swap.nix
    ../modules/filesystem.nix
    ../modules/graphics.nix
    ../modules/networking.nix
    ../modules/power-management.nix
    ../modules/bluetooth.nix
    ## Application installation
    # System
    ../modules/packages.nix
    ../modules/programs.nix
    ../modules/flatpaks.nix
    ../modules/appimages.nix
    # Specific
    # ../modules/nixvim.nix
    ../modules/shell.nix
    # Feature
    ../modules/gaming.nix
    ## Application configurations
    ../modules/neovim.nix
    ../modules/tmux.nix
    ## Service configurations
    ../modules/services.nix
    ../modules/gestures.nix
    ## System environment configurations
    ../modules/environment-variables.nix
    ## Desktop Environments
    # GNOME
    ../modules/gnome-desktop.nix
    # ../modules/gdm.nix
    # KDE
    ../modules/kde-desktop.nix
    ../modules/sddm.nix
    # Cosmic
    # ../modules/cosmic-desktop.nix
  ];


  ## User setup

  users.users.saharsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" ];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;

  ## Enable services

  # Virtualisation and docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  ## Miscellaneous settings

  # Wi-Fi support
  hardware.enableRedistributableFirmware = true;
  boot.kernelModules = [ "kvm-amd" "rtw89" ];
  hardware.usb-modeswitch.enable = true;
  hardware.enableAllFirmware = true;
  # Optional: Use latest kernel for better Realtek driver support
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_6_12;
  # boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.kernelPackages = pkgs.linuxPackages_xanmod;
  # boot.kernelPackages = pkgs.linuxPackages_lqx;
  # boot.kernelPackages = pkgs.linuxPackages_hardened;

}
