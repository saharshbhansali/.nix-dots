{ config, lib, pkgs, ... }:
{

  ## Swap config in hardware-configuration.nix
  # fileSystems."/swap" =
  #   { device = "/dev/disk/by-uuid/38cc3a86-d6bd-4ab1-b372-df6f346eb213";
  #     fsType = "btrfs";
  #     options = [ "subvol=swap" "noatime" ];
  #   };

  # Configure swapfile
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32*1024;
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

}
