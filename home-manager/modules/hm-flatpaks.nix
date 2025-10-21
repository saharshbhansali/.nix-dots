{ config, lib, pkgs, inputs, ... }:

{

  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak.packages = [
    { appId = "com.stremio.Stremio"; origin = "flathub-beta"; }
    # "com.obsproject.Studio"
    # "im.riot.Riot"
  ];

}
