{ config, lib, pkgs, inputs, ... }:

{

  home.packages = with pkgs; [
    hyprlock
    hypridle
    brightnessctl
  ];

  home.file.".config/hypr/hyprlock.conf".source = ../../configs/hypr/hyprlock.conf;
  home.file.".config/hypr/hypridle.conf".source = ../../configs/hypr/hypridle.conf;

}
