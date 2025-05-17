{ config, lib, pkgs, ... }:
{

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
       theme = pkgs.where-is-my-sddm-theme;
    };
  };

}
