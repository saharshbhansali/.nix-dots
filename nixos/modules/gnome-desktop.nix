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
  services.desktopManager.gnome.enable = true;

  # dconf editor for GNOME settings
  programs.dconf.enable = true;

  # GNOME Tweaks
  environment.systemPackages = with pkgs; [
    # gsettings
    nwg-look
    gnome-shell
    gnome-tweaks
    gnomeExtensions.apps
    gnomeExtensions.arcmenu
    # gnomeExtensions.window-gestures
    gnomeExtensions.touchpad-gesture-customization
    # gnomeExtensions.x11-gestures
    gnomeExtensions.dash-to-dock
    # gnomeExtensions.dash-to-panel
    gnomeExtensions.user-themes
    # gnomeExtensions.system-monitor
    gnomeExtensions.pano
    # gnomeExtensions.window-list
    # gnomeExtensions.window-list
    gnomeExtensions.workspace-indicator
    gnomeExtensions.unmess
    # gnomeExtensions.clipboard-indicator
    gnomeExtensions.vitals
    # gnomeExtensions.cmud
    gnomeExtensions.forge
    gnomeExtensions.focus
    # gnomeExtensions.freon
    gnomeExtensions.gmeet
    # gnomeExtensions.gsnap
    # gnomeExtensions.gtile
    gnomeExtensions.gdeej
    # gnomeExtensions.sermon
    gnomeExtensions.docker
    # gnomeExtensions.copier
    # gnomeExtensions.clipqr
    # gnomeExtensions.volume-boost
    gnomeExtensions.boost-volume
    gnomeExtensions.yakuake
    gnomeExtensions.zilence
    gnomeExtensions.wallhub
  ];
}
