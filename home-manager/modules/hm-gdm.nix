{ config, lib, pkgs, inputs, ... }:

{

  # Set numlock
  dconf.settings = {

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
      remember-numlock-state = true;
    };

    "org/gnome/settings-daemon/peripherals/keyboard" = {
      numlock-state = true;
    };

  };

}
