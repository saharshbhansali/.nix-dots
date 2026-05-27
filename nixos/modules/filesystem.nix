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

  ## Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  ## BTRFS optimizations

  ## Scrubbing
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";  # Reduced from weekly for less I/O interference
  };

  ## Deduping
  # NOTE:
  # run dedupe per subvolume, not on entire filesystem
  # Also, always (if doing so) defragment *before* deduping
  # WARNING:
  # DO NOT dedupe /nix/store and /boot, and use CAUTION while deduping /var

  ## Beesd
  services.beesd.filesystems = {
    root = {
      # spec = "LABEL=root"; # or "/dev/disk/by-uuid/..." or subvol path
      spec = "/"; # mount point
      hashTableSizeMB = 128; # ~128MiB per TiB of data
      verbosity = "crit";
      extraOptions = [ "--thread-count=2" "--loadavg-target" "2.0" ];
    };
    home = {
      # spec = "LABEL=nix-home";
      spec = "/home";
      hashTableSizeMB = 128;
      verbosity = "crit";
      extraOptions = [ "--thread-count=2" "--loadavg-target" "2.0" ];
    };
  };
  ## To disable autostart, run the following for each filesystem
  systemd.services."beesd@root".wantedBy = lib.mkForce [];
  systemd.services."beesd@home".wantedBy = lib.mkForce [];
  ## Start manually by running: systemctl start beesd@<filesystem>

  ## Duperemove
  # 1. Check status
  # # sudo btrfs scrub status /home
  # 2. Dry run
  # # sudo duperemove -r -d -h --hashfile=/var/lib/duperemove-home.hash /home
  # 3. Dedupe
  # # sudo duperemove -r --limit=2G -h --hashfile=/var/lib/duperemove-home.hash /home
  environment.systemPackages = with pkgs; [
    duperemove
    bees
  ];

  ## Gaming specialization: disable BTRFS scrub during gaming
  specialisation = {
    gaming.configuration = {
      services.btrfs.autoScrub.enable = lib.mkForce false;
    };
  };

}
