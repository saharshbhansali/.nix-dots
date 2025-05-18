{ config, lib, pkgs, ... }:

{

  # Enable GDM
  services.xserver.enable =  true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland.enable = true;

}
