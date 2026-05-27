{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # ## For NixOS
    # inputs.spicetify-nix.nixosModules.default

    ## For home-manager
    inputs.spicetify-nix.homeManagerModules.default
  ];

  programs.spicetify = let
    # ## For Flakeless:
    # spicePkgs = spicetify-nix.packages;
    ## With flakes:
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    enable = true;
    alwaysEnableDevTools = true;

    ## Example
    # theme = spicePkgs.themes.catppuccin;
    # colorScheme = "mocha";
    theme = spicePkgs.themes.text;

    enabledExtensions = with spicePkgs.extensions; [
      ## Example
      # adblockify
      # hidePodcasts

      shuffle # shuffle+ (special characters are sanitized out of extension names)
      bookmark
      history
      playNext
      oldLikeButton

      powerBar
      # seekSong
      playlistIcons
      # phraseToPlaylist
      volumePercentage
      autoVolume
    ];

    enabledCustomApps = with spicePkgs.apps; [
      newReleases
      ncsVisualizer
    ];

    enabledSnippets = with spicePkgs.snippets; [
      rotatingCoverart
      pointer
    ];
  };

  # home.packages = with pkgs; [
  #   config.programs.spicetify.spicedSpotify
  # ];
}
