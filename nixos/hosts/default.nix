{ config, lib, pkgs, inputs, ... }:

{

  system.stateVersion = "24.11";

  ## Nix settings

  # System settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.download-buffer-size = 524288000;

  # # Trusted-users list
  nix.settings.trusted-users = [ "root" "saharsh" ];

  # Extra options
  nix.extraOptions = ''
    # Add cachix binary caches
    extra-substituters = https://devenv.cachix.org
    extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
  '';


  ## Package/module imports

  imports = [
    ## System configuration
    ../modules/bootloader.nix
    ../modules/swap.nix
    ../modules/filesystem.nix
    ../modules/shell.nix
    ## Application installation
    ../modules/packages.nix
    ../modules/programs.nix
    ../modules/services.nix
    ## Application configurations
    # ../modules/nixvim.nix
    ../modules/neovim.nix
    ../modules/tmux.nix
    ## Service configurations
    ../modules/gestures.nix
    ## Desktop Environment configurations
    ../modules/gnome-desktop.nix
    # ../modules/gdm.nix
    ../modules/kde-desktop.nix
    ../modules/sddm.nix
    # ../modules/cosmic-desktop.nix
  ];


  ## User setup

  users.users.saharsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;

  ## Enable services

  # Networking services
  networking.networkmanager.enable = true;
  networking.hostName = "nixos";

  # Flatpak
  services.flatpak.enable = true;

  # Virtualisation and docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  ## Miscellaneous settings

}
