{ config, lib, pkgs, inputs, ... }:

{

  ## Application desktop files
  home.file.".local/share/applications/spotify.desktop".source = ../../configs/applications/spotify.desktop;

}

