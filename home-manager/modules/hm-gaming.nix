{ config, lib, pkgs, inputs, ... }:

{

  # ## GPU drivers
  # services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];

  # ## Enable gamemode
  # programs.gamemode.enable = true;

  # ## Steam
  # programs.steam = {
  #   enable = true;
  #   gamescopeSession.enable = true;
  #   remotePlay.openFirewall = true;
  #   dedicatedServer.openFirewall = true;
  #   extraCompatPackages = [ pkgs.proton-ge-bin];
  # };

  ## Gaming packages
  home.packages = with pkgs; [
    # HUD for system performance
    mangohud

    # Proton & Wine
    protonup-ng
    wineWowPackages.stable
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

  home.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

}

