{
  config,
  lib,
  pkgs,
  ...
}: {
  ## Enable services
  # XDG
  xdg.autostart.enable = true;

  # Allow unprivileged users to manage their own cgroup hierarchies
  systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

  systemd.packages = [
    (
      pkgs.writeTextFile {
        name = "delegate.conf";
        text = ''
          [Service]
          Delegate=yes
        '';
        destination = "/etc/systemd/system/user@.service.d/delegate.conf";
      }
    )
  ];

  # Atuin daemon
  systemd.user.services.atuind = {
    enable = true;
    environment = {
      ATUIN_LOG = "info";
    };
    serviceConfig = {
      ExecStart = "${pkgs.atuin}/bin/atuin daemon";
    };
    after = ["network.target"];
    wantedBy = ["default.target"];
  };

  # Plocate - system-wide file search
  services.locate = {
    enable = true;
    interval = "daily";
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
