{ ... }:

{

  # libinput gestures
  services.libinput.enable = true;

  # multi-touch gesture recognizer
  services.touchegg.enable = true;

  services.xserver.windowManager.fvwm2.gestures = true;

}
