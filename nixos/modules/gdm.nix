{ config, lib, pkgs, ... }:

{

  # Enable GDM
  services.xserver.enable =  true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;

}
