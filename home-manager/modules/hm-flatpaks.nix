{ config, lib, pkgs, inputs, ... }:

{

  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak.remotes = [{
    name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
  }];

  services.flatpak.packages = [
    { appId = "com.stremio.Stremio"; origin = "flathub-beta"; }
    # "com.obsproject.Studio"
    # "im.riot.Riot"
  ];

}
