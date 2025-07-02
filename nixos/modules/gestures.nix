{ config, lib, pkgs, ... }:

{

  # libinput gestures
  services.libinput.enable = true;

  # multi-touch gesture recognizer
  services.touchegg.enable = true;

  services.xserver.windowManager.fvwm2.gestures = true;

  ## Create a service to launch the gestures daemon
  systemd.user.services.libinput-gestures-service = {
    enable = true;
    description = "libinput gestures daemon";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
    };
    path = with pkgs; [
      wmctrl
      pamixer
      xdotool
    ];
  };

}
