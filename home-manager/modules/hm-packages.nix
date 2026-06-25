{
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: {
  ## Install packages
  # nixpkgs.config.allowUnfree = true;

  ## User level packages
  home.packages =
    with pkgs; [
      ## Terminal programs
      chezmoi
      grc

      ## VCS
      oh-my-git
      graphite-cli
      mercurial
      lazyjj
      jjui
      # jj-fzf
      distrobox-tui
      distroshelf

      ## Terminal emulators
      wezterm

      ## Disk utils
      # ventoy-full
      # ventoy
      # ventoy-full-qt
      # ventoy-full-gtk
      impression
      spacedrive

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
      (
        (vivaldi.overrideAttrs (oldattrs: {
          dontwrapqtapps = false;
          dontpatchelf = true;
          nativeBuildInputs = oldattrs.nativeBuildInputs ++ [pkgs.kdePackages.wrapQtAppsHook];
        })).override
        {
          commandLineArgs = [
            "--enable-features=TouchpadOverscrollHistoryNavigation"
            "--password-store=kwallet5"
          ];
          proprietaryCodecs = true;
          enableWidevine = true;
        }
      )
      inputs.browseros-ai.packages.${stdenv.hostPlatform.system}.browseros-ai
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
      proton-vpn
      cloudflare-warp
      cloudflare-cli
      wgcf

      ## LLMs
      aichat
      ollama
      lmstudio
      # ollama-cuda
      open-webui
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
      # mpv and vlc are in system packages (nixos/modules/packages.nix)
      # stremio-linux-shell
      # obs-studio
      pulsemeeter
      mediainfo-gui

      ## Notes
      obsidian
      appflowy
      notion-app-enhanced

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
      calibre
      zathura

      ## Launcher
      # vicinae
      # albert
      # wox

      ## Chat Applications
      # whatsie
      # wasistlos
      karere
      whatsapp-electron

      # Anki
      (anki.withAddons [
        ankiAddons.passfail2
        ankiAddons.anki-connect
        ankiAddons.review-heatmap
        ankiAddons.fsrs4anki-helper
      ])
    ]
    # ++ (
    #   with args.pkgs-stable; [
    #   ]
    # )
    ;
}
