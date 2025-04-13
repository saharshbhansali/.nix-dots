{ config, lib, pkgs, ... }:
{

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

}
