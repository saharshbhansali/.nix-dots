{ ... }:

{

  # libinput gestures
  services.libinput.enable = true;

  # multi-touch gesture recognizer
  services.touchegg.enable = true;

  services.xserver.windowManager.fvwm2.gestures = true;

  ## Create a service to launch the gestures daemon
  systemd.user.services.libinput-gestures-service = {
    description = "libinput gestures daemon";
    script = ''
      libinput-gestures
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
