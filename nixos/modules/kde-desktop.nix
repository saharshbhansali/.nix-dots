{ config, pkgs, lib, inputs, ... }:
{

  # imports = [
  #   ./sddm.nix
  # ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };
  xdg.portal.config.common.default = "*";

  # KDE Plasma
  services.desktopManager.plasma6.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

}
