{ config, lib, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    catppuccin-grub
  ];

  ## Performance-optimized kernel parameters
  boot.kernelParams = [
    "iommu=pt"              # Pass-through IOMMU for better device performance
    "schedutil"             # Better CPU governor for desktop responsiveness
    "debug=0"               # Disable kernel debugging overhead
  ];

  ## Config hibernate/suspend/resume settings (via systemd)
  boot.initrd.systemd.enable = true;

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
      default = "saved";
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
