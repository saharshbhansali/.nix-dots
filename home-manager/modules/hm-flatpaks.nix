{ config, lib, pkgs, inputs, ... }:

{

  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  # Append additional remotes to default remote 'flathub'
  services.flatpak.remotes = lib.mkOptionDefault [{
    name = "flathub-beta";
    location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
  }];

  # Automatically update flatpaks
  services.flatpak.update.auto = {
    enable = true;
    onCalendar = "weekly"; # Default value
  };

  # List of flatpaks to install
  services.flatpak.packages = [
    { appId = "com.stremio.Stremio"; origin = "flathub-beta"; }
    # "com.obsproject.Studio"
    # "im.riot.Riot"
  ];

}
