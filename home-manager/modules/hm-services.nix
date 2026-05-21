{ config, lib, pkgs, inputs, ... }:

{

  # Services
  # Autostart vicinae via systemd
  systemd.user.services.vicinae-autostart = {
    Unit = {
      Description = "Vicinae Server Daemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      # Specify the service type. 'simple' is the default and common for daemons
      # where the main process is the one started by ExecStart.
      Type = "simple";

      # The ExecStart command needs to be wrapped in a shell to interpret '||'.
      # It's generally good practice to explicitly use bash from pkgs.
      # The single quotes around the command ensure the whole string is passed to bash -c.
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.vicinae}/bin/vicinae server --replace || ${pkgs.vicinae}/bin/vicinae server'";

      # Set a working directory for the service. This can be important for
      # applications that look for configuration files or write logs relative
      # to their current working directory. Defaults to the user's home directory
      # for user services if not specified, but being explicit is often better.
      WorkingDirectory = "%h"; # %h expands to the user's home directory

      # Recommended for daemons to ensure they restart if they crash.
      Restart = "on-failure";
      # Time to wait before restarting the service after a failure.
      RestartSec = "5s";

      # Consider adding ExecStop for graceful shutdown if vicinae has a specific
      # stop command. Otherwise, systemd will send SIGTERM by default.
      # Example: ExecStop = "${pkgs.vicinae}/bin/vicinae server --stop";
      # Assuming SIGTERM is sufficient for now.
    };

    Install = {
      # Ensure the service is enabled and starts with the graphical session.
      WantedBy = [ "graphical-session.target" ];
    };
  };

}
