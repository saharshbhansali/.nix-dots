{ config, lib, pkgs, inputs, ... }:

{

  system.stateVersion = "24.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.download-buffer-size = 524288000;

  imports = [
    ## System configuration
    ../modules/bootloader.nix
    ../modules/swap.nix
    ../modules/filesystem.nix
    ## Application installation
    ../modules/packages.nix
    ../modules/programs.nix
    ## Application configurations
    ../modules/nixvim.nix
    ## Service configurations
    ../modules/gestures.nix
    ## Desktop Environment configurations
    ../modules/gnome-desktop.nix
    ../modules/gdm.nix
    # ../modules/kde-desktop.nix
    # ../modules/sddm.nix
    # ../modules/cosmic-desktop.nix
  ];


  users.users.saharsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;

  ## Enable services


  networking.networkmanager.enable = true;
  networking.hostName = "nixos";


  services.flatpak.enable = true;


  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };


}
