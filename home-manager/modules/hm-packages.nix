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
    inputs.zen-browser.packages.${stdenv.hostPlatform.system}.twilight
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
    tor-browser
    # text-based/terminal web browser
    chawan
    browsh
    elinks
    links2
    lynx
    w3m

    ## VPN software
    # protonvpn-gui
    # cloudflare-warp
    # cloudflare-cli
    # wgcf

    ## LLMs
    aichat
    ollama
    # ollama-cuda
    kdePackages.alpaka
    alpaca
    oterm
    litellm

    # AI Coding agents
    opencode
    claude-code
    # vimPlugins.opencode-nvim
    # vimPlugins.claudecode-nvim

    ## Media
    mpv
    vlc
    # stremio
    obs-studio
    pulsemeeter

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
