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

    ## VCS
    graphite-cli
    mercurial
    jujutsu
    lazyjj
    jjui
    jj-fzf

    # ## Disk utils
    # ventoy-full

    ## Spotify
    # spotify
    # spicetify-cli
    spotifyd
    spotify-player
    spotify-cli-linux
    # spotify-tui

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
    # text-based/terminal web browser
    chawan
    browsh
    elinks
    links2
    lynx
    w3m

    ## VPN software
    protonvpn-cli
    protonvpn-gui
    cloudflare-warp
    cloudflare-cli
    wgcf

    ## LLMs
    aichat
    ollama
    # ollama-cuda
    kdePackages.alpaka
    alpaca
    oterm
    litellm

    ## Media
    mpv
    vlc
    # stremio
    obs-studio

    ## Notes
    obsidian

    ## TUI apps
    # ytui-music
    youtube-tui
    wiki-tui
    systemctl-tui

    # Torrent
    qbittorrent

    ## Other Programs
    ## RSS Feed
    newsboat

    ## KDE Utils
    konsave

    ## Document viewers
    zathura

    ## Launcher
    albert
    # wox

  ];

}
