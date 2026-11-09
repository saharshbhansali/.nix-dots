{config, ...} @ args: let
  user = args.username;
  home = config.users.users.${user}.home;

  cfg = "${home}/searxng/core-config";
  data = "${home}/.local/share/containers";
in {
  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      degoog = {
        image = "ghcr.io/fccview/degoog:latest";
        ports = [
          "4444:4444"
        ];
        volumes = [
          "${data}/degoog:/app/data"
        ];
        podman.user = user;
      };

      searxng-valkey = {
        image = "docker.io/valkey/valkey:9-alpine";
        cmd = [
          "valkey-server"
          "--save"
          "30"
          "1"
          "--loglevel"
          "warning"
        ];
        volumes = [
          "${data}/searxng/valkey:/data"
        ];
        podman.user = user;
      };

      searxng-core = {
        image = "docker.io/searxng/searxng:latest";
        ports = [
          "8080:8080"
        ];
        environmentFiles = [
          "${cfg}/.env"
        ];
        volumes = [
          "${cfg}:/etc/searxng:ro"
          "${data}/searxng/cache:/var/cache/searxng"
        ];
        dependsOn = [
          "searxng-valkey"
        ];
        podman.user = user;
      };
    };
  };

  # Create persistent directories owned by the container user.
  systemd.tmpfiles.rules = [
    "d ${data} 0750 ${user} users - -"
    "d ${data}/degoog 0750 ${user} users - -"
    "d ${data}/searxng 0750 ${user} users - -"
    "d ${data}/searxng/valkey 0750 ${user} users - -"
    "d ${data}/searxng/cache 0750 ${user} users - -"
  ];
}
