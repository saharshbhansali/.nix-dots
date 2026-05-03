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

  ## Gaming specialization: optimize kernel parameters for gaming
  # NOTE: Hibernate (S4) saves system state - resume must use same specialization
  specialisation = {
    gaming.configuration = {
      # Gaming-optimized kernel params
      boot.kernelParams = [
        "iommu=pt"              # Pass-through IOMMU
        "queue_depth=32"        # Better I/O for games
      ];

      # Increase VM max map count for some games (default: 65530)
      boot.kernel.sysctl."vm.max_map_count" = 524288;  # 512k - sufficient for games without excessive limits
    };
  };

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
