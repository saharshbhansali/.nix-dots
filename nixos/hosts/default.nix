{ config, pkgs, inputs, lib, ... }:

{
  system.stateVersion = "24.11";


  imports = [
    ../modules/packages.nix
    ../modules/nixvim.nix
    ../modules/kde-desktop.nix
    # ../modules/gnome-desktop.nix
    ../modules/sddm.nix
  ];


  ## Configure bootloader - GRUB
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
       enable = lib.mkDefault true;
       efiSupport = true;
       useOSProber = true;
       #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
       devices = ["nodev"];
    };
  };


  ## Mount disk partitions
  fileSystems = {
    "/user/lfs" = {
      device = "/dev/disk/by-uuid/2c013b70-8636-4b0c-824f-47cee3521721";
      fsType = "btrfs";
      options = [ "noauto" "nofail" "noexec" "users" ];
    };

    "/user/data" = {
      device = "/dev/disk/by-uuid/ab314217-2ceb-45cb-bdea-2c98961b9367";
      fsType = "btrfs";
      options = [ "noauto" "nofail" "noexec" "users" ];
    };
  };

  # Configure swapfile
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8*1024;
    }
  ];

  # Enable zram
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
    priority = 1;
    # writebackDevice = "/swapfile";
  };


  networking.hostName = "nixos";


  users.users.saharsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.zsh;
  };


  ## Enable services

  services.flatpak.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  networking.networkmanager.enable = true;

}
