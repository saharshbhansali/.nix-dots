{ config, pkgs, inputs, lib, ... }:

{

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.11";


  imports = [
    ../modules/bootloader.nix
    ../modules/swap.nix
    ../modules/filesystem.nix
    ../modules/packages.nix
    ../modules/nixvim.nix
    ../modules/kde-desktop.nix
    # ../modules/gnome-desktop.nix
    ../modules/sddm.nix
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
