{
  config,
  lib,
  pkgs,
  ...
}: let
  localServices = {
    degoog = 4444;
    searxng = 8080;
  };

  localTlds = ["internal" "localhost" "test" "pod" "loc"];

  # Generates all combinations of { service = ...; tld = ...; }
  combinations = lib.cartesianProduct {
    service = builtins.attrNames localServices;
    tld = localTlds;
  };

  # Create a cloaking rules file in the Nix store for *.[internal|localhost|test|pod|loc]
  cloakingRules = pkgs.writeText "cloaking-rules.txt" (
    lib.concatMapStringsSep "\n" (tld: ''
      *.${tld} 127.0.0.1
      *.${tld} ::1
    '')
    localTlds
  );
in {
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

  services.dnscrypt-proxy.settings.cloaking_rules = "${cloakingRules}";
  # Caddy - lightweight reverse proxy
  # Route *.internal domains to your Home Manager Podman container ports
  services.caddy = {
    enable = true;
    virtualHosts = builtins.listToAttrs (map (c: {
        name = "http://${c.service}.${c.tld}";
        value.extraConfig = ''
          reverse_proxy localhost:${toString localServices.${c.service}}
        '';
      })
      combinations);
  };

  ## Gaming specialization: reduce logging overhead
  specialisation = {
    gaming.configuration = {
      services.journald.settings.Journal = {
        SystemMaxUse = "50M";
        RuntimeMaxUse = "10M";
      };
    };
  };
}
