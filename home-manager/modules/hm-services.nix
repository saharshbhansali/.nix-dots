{ config, lib, pkgs, inputs, ... }:

{

  # Services
  # Autostart vicinae via systemd
  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae Server Daemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      # Path to the executable. If using an AppImage, replace with the absolute path, 
      # e.g., "/home/username/Applications/vicinae.AppImage --server"
      ExecStart = "${pkgs.vicinae}/bin/vicinae server --replace || ${pkgs.vicinae}/bin/vicinae server";
      
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

}
