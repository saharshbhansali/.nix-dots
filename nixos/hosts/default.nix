{ config, pkgs, inputs, ... }:

{
  imports = [
    ../modules/common-packages.nix
    ../modules/kde-desktop.nix
    # ../modules/gnome-desktop.nix
    # ../modules/nixvim-system.nix  # optional: nixvim via system
  ];

  networking.hostName = "nixos";

  users.users.saharsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "24.11";
}
