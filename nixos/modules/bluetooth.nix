{
  pkgs,
  nixpkgs,
  lib,
  config,
  ...
}: {
  hardware.bluetooth.enable = true;

  systemd.services.disable-bt-before-sleep = {
    description = "Disable Bluetooth before suspend/hibernate";
    wantedBy = ["sleep.target"];
    before = ["sleep.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl stop bluetooth.service";
    };
  };
}
