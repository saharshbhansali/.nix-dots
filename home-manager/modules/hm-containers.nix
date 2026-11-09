{config, ...}: let
  cfg = "${config.home.homeDirectory}/searxng/core-config";
  data = "${config.xdg.dataHome}/containers";
in {
  sops.secrets."searxng/secret_key" = {};
  sops.templates."searxng-env".content = ''
    SEARXNG_SECRET=${config.sops.placeholder."searxng/secret_key"}
  '';

  services.podman = {
    enable = true;

    networks.searxng = {
      driver = "bridge";
    };

    containers = {
      degoog = {
        image = "ghcr.io/fccview/degoog:latest";
        ports = [
          "4444:4444"
        ];
        volumes = [
          "${data}/degoog:/app/data"
        ];
      };

      searxng-valkey = {
        image = "docker.io/valkey/valkey:9-alpine";
        exec = "valkey-server --save 30 1 --loglevel warning";
        volumes = [
          "${data}/searxng/valkey:/data"
        ];
        network = "searxng.network";
        networkAlias = ["searxng-valkey"];
      };

      searxng-core = {
        image = "docker.io/searxng/searxng:latest";
        ports = [
          "8080:8080"
        ];
        environmentFile = [
          # "${cfg}/.env"
          config.sops.templates."searxng-env".path
        ];
        volumes = [
          # "${cfg}:/etc/searxng:ro"
          # "${cfg}:/etc/searxng:Z,U"
          "${cfg}/settings.yml:/etc/searxng/settings.yml:ro"
          "${cfg}/limiter.toml:/etc/searxng/limiter.toml:ro"
          "${data}/searxng/cache:/var/cache/searxng"
        ];
        network = "searxng.network";
        extraConfig = {
          Unit = {
            Requires = "podman-searxng-valkey.service";
            After = "podman-searxng-valkey.service";
          };
          Container = {
            UserNS = "keep-id:uid=977,gid=977";
          };
        };
      };
    };
  };

  home.activation.createContainerData = ''
    $DRY_RUN_CMD mkdir -p \
      ${data}/degoog \
      ${data}/degoog/data \
      ${data}/searxng/valkey \
      ${data}/searxng/cache
  '';
}
