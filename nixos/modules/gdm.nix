{ config, lib, pkgs, ... }:

{

  # Enable GDM
  services.xserver.enable =  true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;

  # Fix ssh-askpass conflict
  programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

  environment.systemPackages = with pkgs; [

    gdm-settings

  ];

}
