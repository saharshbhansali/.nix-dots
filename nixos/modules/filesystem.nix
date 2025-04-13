{ config, lib, pkgs, ... }:
{

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

}
