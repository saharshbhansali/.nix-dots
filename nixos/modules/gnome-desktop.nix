{ pkgs, config, lib, inputs, ... }:

{

  # imports = [
  #   ./gdm.nix
  # ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  xdg.portal.config.common.default = "*";

  # Enable GNOME
  services.xserver.desktopManager.gnome.enable = true;

  # dconf editor for GNOME settings
  programs.dconf.enable = true;

  # GNOME Tweaks
  environment.systemPackages = with pkgs; [
    # gsettings
    nwg-look
    gnome-shell
    gnome-tweaks
    gnomeExtensions.apps
    gnomeExtensions.dash-to-dock
    gnomeExtensions.dash-to-panel
    gnomeExtensions.user-themes
    gnomeExtensions.system-monitor
    gnomeExtensions.pano
    gnomeExtensions.window-list
    gnomeExtensions.workspace-indicator
    gnomeExtensions.unmess
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.vitals
    gnomeExtensions.cmud
    gnomeExtensions.forge
    gnomeExtensions.focus
    gnomeExtensions.freon
    gnomeExtensions.gmeet
    gnomeExtensions.gsnap
    gnomeExtensions.gtile
    gnomeExtensions.gdeej
    gnomeExtensions.sermon
    gnomeExtensions.docker
    gnomeExtensions.copier
    gnomeExtensions.clipqr
    gnomeExtensions.yakuake
    gnomeExtensions.zilence
    gnomeExtensions.wallhub
    gnomeExtensions.arcmenu
  ];
}
