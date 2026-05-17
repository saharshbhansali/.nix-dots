{ config, lib, pkgs, inputs, ... }:

{

  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # Flatpak
  services.flatpak.enable = true;

}
