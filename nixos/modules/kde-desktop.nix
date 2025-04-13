{ config, pkgs, lib, inputs, ... }:
{

  # KDE Plasma
  services.desktopManager.plasma6.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

}
