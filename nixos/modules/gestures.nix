{
  config,
  lib,
  pkgs,
  ...
}: {
  # libinput gestures
  services.libinput.enable = true;

  # # multi-touch gesture recognizer
  # services.touchegg.enable = true;

  services.xserver.windowManager.fvwm2.gestures = true;

  ## Create a service to launch the gestures daemon
  systemd.user.services.libinput-gestures-service = {
    enable = true;
    description = "libinput gestures daemon";

    # Ensure it waits specifically for the graphical session to be active
    after = ["graphical-session.target"];
    requisite = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];

    serviceConfig = {
      ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures -c /etc/libinput-gestures.conf";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    path = with pkgs; [
      wmctrl
      pamixer
      xdotool
      libinput-gestures
      coreutils
    ];
  };

  # Gestures configuration
  environment.etc."libinput-gestures.conf".source = ../../configs/gestures/libinput-gestures.conf;
  environment.etc."gestures/alt_tab_switcher/alt_tab.sh".source =
    ../../configs/gestures/alt_tab_switcher/alt_tab.sh;
}
