{ config, lib, pkgs, inputs, ... }:

{

  ## Install packages
  # nixpkgs.config.allowUnfree = true;

  ## User level packages
  home.packages = with pkgs; [

    ## Terminal programs
    chezmoi
    grc
    tdf

    # ## Disk utils
    # ventoy-full

    ## Spotify
    spotify
    spicetify-cli
    # spotify-tui
    # spotifyd

    ## Browsers
    # zen
    inputs.zen-browser.packages.${system}.twilight
    # vivaldi
    ((vivaldi.overrideAttrs
      (oldattrs: {
        dontwrapqtapps = false;
        dontpatchelf = true;
        nativeBuildInputs = oldattrs.nativeBuildInputs ++ [pkgs.kdePackages.wrapQtAppsHook];
    })).override {
      commandLineArgs = [
        "--enable-features=TouchpadOverscrollHistoryNavigation"
        "--password-store=kwallet5"
      ];
      proprietaryCodecs = true;
      enableWidevine = true;
    })
    # firefox and chromium
    firefox
    chromium

    ## Other Programs
    stremio
    obsidian
    zathura

    ## Launcher
    wox
    albert

    ## VPN software
    protonvpn-cli
    protonvpn-gui
    cloudflare-warp
    cloudflare-cli
    wgcf

    ## KDE Utils
    konsave

    ## LLMs
    ollama
    # ollama-cuda
    kdePackages.alpaka
    alpaca
    oterm
    litellm

  ];

}
