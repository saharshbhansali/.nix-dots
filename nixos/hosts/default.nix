{ config, lib, pkgs, inputs, ... }:

{

  system.stateVersion = "24.11";

  ## Nix settings

  # System settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.download-buffer-size = 524288000;

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
    ../modules/bootloader.nix
    ../modules/swap.nix
    ../modules/filesystem.nix
    ../modules/shell.nix
    ## Application installation
    ../modules/packages.nix
    ../modules/programs.nix
    ../modules/services.nix
    ../modules/flatpaks.nix
    ## Application configurations
    # ../modules/nixvim.nix
    ../modules/neovim.nix
    ../modules/tmux.nix
    ## Service configurations
    ../modules/gestures.nix
    ## Desktop Environment configurations
    ../modules/gnome-desktop.nix
    # ../modules/gdm.nix
    ../modules/kde-desktop.nix
    ../modules/sddm.nix
    # ../modules/cosmic-desktop.nix
  ];


  ## User setup

  users.users.saharsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;

  ## Enable services

  # Networking services
  networking.networkmanager.enable = true;
  networking.wireless.enable = false;
  networking.hostName = "nixos";

  # Flatpak
  services.flatpak.enable = true;

  # Virtualisation and docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  ## Miscellaneous settings

  # Wi-Fi support
  boot.kernelParams = [
    "pcie_aspm.policy=performance"
    "rtw89_pci.disable_ps_mode=1"
  ];
  hardware.firmware = [ pkgs.linux-firmware ];
  # boot.kernelModules = [ "rtw89" ];
  boot.kernelModules = [ "rtw89pci" ];
  hardware.enableRedistributableFirmware = true;
  # boot.extraModulePackages = with config.boot.kernelPackages; [ rtw89 ];
  hardware.usb-modeswitch.enable = true;
  hardware.enableAllFirmware = true;
  # Optional: Use latest kernel for better Realtek driver support
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_6_10;

}
