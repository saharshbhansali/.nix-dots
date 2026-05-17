{ config, lib, pkgs, inputs, ... }:
{

  # Enable containerization
  virtualisation.containers.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };

  # Prevent Docker from auto-starting
  systemd.services.docker.wantedBy = lib.mkForce [ ]; # Don't auto-start
  # Manual activation: sudo systemctl start docker

}
