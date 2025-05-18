{ config, lib, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    catppuccin-grub
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
      theme = pkgs.catppuccin-grub;
      # theme = pkgs.stdenv.mkDerivation {
      #   pname = "distro-grub-themes";
      #   version = "3.1";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "AdisonCavani";
      #     repo = "distro-grub-themes";
      #     rev = "v3.1";
      #     hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
      #   };
      #   installPhase = "cp -r customize/nixos $out";
      # };
    };
  };

}
