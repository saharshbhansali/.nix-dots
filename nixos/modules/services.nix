{ config, lib, pkgs, ... }:

{

  ## Enable services
  # XDG
  xdg.autostart.enable = true;

  # Atuin daemon
  systemd.user.services.atuind = {
    enable = true;
    environment = {
      ATUIN_LOG = "info";
    };
    serviceConfig = {
      ExecStart = "${pkgs.atuin}/bin/atuin daemon";
    };
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];
  };

  ## Gaming specialization: reduce logging overhead
  specialisation = {
    gaming.configuration = {
      services.journald.extraConfig = ''
        SystemMaxUse=50M
        RuntimeMaxUse=10M
      '';
    };
  };

}
