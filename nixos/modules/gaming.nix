{ config, lib, pkgs, inputs, ... }:

{

  ## Enable gamemode
  programs.gamemode.enable = true;

  ## Steam
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin];
  };

  # Hardware support
  hardware.steam-hardware.enable = true;

  ## Gaming packages
  environment.systemPackages = with pkgs; [
    steam
    steam-unwrapped
    steam-run
    steam-devices-udev-rules

    # HUD for system performance
    mangohud

    # Proton & Wine
    protonup-ng
    wineWow64Packages.stable
    # wine
    # wine64

    # Launchers
    lutris
    heroic
    bottles

    # Extras
    playonlinux
    protontricks
    protonplus
    protonup-qt
    winetricks

    # Controllers
    dualsensectl
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };

  # Hidraw rules for PS5 controller
  # ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", TAG+="uaccess"
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666"
  '';

}

