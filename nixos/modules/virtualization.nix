{
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: {
  # Add user to groups for containerization
  users.users.${args.username}.extraGroups = ["podman" "libvirtd" "kvm"];

  # Enable containerization
  virtualisation.containers.enable = true;

  virtualisation = {
    podman = {
      enable = true;

      # # Create a `docker` alias for podman, to use it as a drop-in replacement
      # dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    docker = {
      enable = true;
      storageDriver = "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      autoPrune = {
        enable = true;
        persistent = true;
        randomizedDelaySec = "15min";
        dates = "monthly";
      };
    };

    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true; # Optional: TPM support (e.g., for Windows 11)
    };
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;

  boot.binfmt = {
    emulatedSystems = ["aarch64-linux"];
    preferStaticEmulators = true; # required to work with podman
  };

  # Prevent Docker from auto-starting
  systemd.services.docker.wantedBy = lib.mkForce []; # Don't auto-start
  # Manual activation: sudo systemctl start docker

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    ## Containerization
    # Docker
    docker-compose # docker - start group of containers for dev
    # Podman
    podman-compose # podman - start group of containers for dev
    podman-tui # status of containers in the terminal
    podman-desktop # graphical tool for developing on containers and Kubernetes
    pods # podman desktop application
    # Misc utils
    dive # look into docker image layers
    slirp4netns # user-mode TCP/IP networking (via slirp) for unprivileged Linux network namespaces
    ## Virtualization
    # VMWare
    vmware-workstation
    # QEMU
    qemu
    qemu-user # QEMU userspace emulator
    qemu-utils
    # Virt-Manager
    virt-manager
    virt-viewer
    # Misc
    spice
    spice-gtk
    spice-protocol
    virtio-win
  ];
}
