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

    ## Fish plugins
    fishPlugins.z
    fishPlugins.plugin-git
    fishPlugins.git-abbr
    # fishPlugins.fzf
    fishPlugins.fzf-fish
    fishPlugins.transient-fish
    fishPlugins.grc
    fishPlugins.colored-man-pages
    fishPlugins.bass

    ## Official nushell plugins available in nixpkgs-unstable
    nushellPlugins.semver
    nushellPlugins.query        # SQL-like query support
    nushellPlugins.net
    nushellPlugins.highlight    # syntax highlighting
    nushellPlugins.units
    nushellPlugins.polars       # DataFrame support via Polars (super powerful)
    nushellPlugins.gstat        # git plugin
    nushellPlugins.formats
    nushellPlugins.dbus

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

    # ## VS Code
    # vscode-fhs
    # vscodium
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        github.copilot
        github.copilot-chat
        supermaven.supermaven
        tabnine.tabnine-vscode

        ms-azuretools.vscode-docker

        bbenoist.nix
        ms-python.python
        ms-python.debugpy

        # catppuccin.cattppuccin-vscode
      ];
    })
    vimPlugins.supermaven-nvim
    # ## Helix editor
    helix
    # evil-helix
    # helix-gpt

    ## Other Programs
    stremio
    obsidian
    zathura

    ## Launcher
    wox
    albert
    ulauncher

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
