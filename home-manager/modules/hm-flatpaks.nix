{ config, lib, pkgs, inputs, ... }:

{

  imports = [ inputs.flatpaks.homeModules.default ];

  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    packages = [
      ## Examples
      # "flathub:app/org.kde.index//stable"
      # "flathub-beta:app/org.kde.kdenlive/x86_64/stable"
      # ":${./foobar.flatpak}"
      # "flathub:/root/testflatpak.flatpakref"
      "flathub-beta:app/com.stremio.Stremio/x86_64/stable"
    ];
  };

}
