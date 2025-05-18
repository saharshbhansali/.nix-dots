{ config, lib, pkgs, ... }:

{

  imports = [
    ./gnome-desktop.nix
    ./gdm.nix
  ];

  environment.systemPackages = with pkgs; [
  ];

}
