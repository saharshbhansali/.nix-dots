{ config, lib, pkgs, inputs, ... }:

{

  ## Install packages
  # nixpkgs.config.allowUnfree = true;

  # User level packages
  home.packages = with pkgs; [

    # Terminal programs
    chezmoi
    grc

    # Fish plugins
    fishPlugins.z
    fishPlugins.plugin-git
    fishPlugins.git-abbr
    # fishPlugins.fzf
    fishPlugins.fzf-fish
    fishPlugins.transient-fish
    fishPlugins.grc
    fishPlugins.colored-man-pages
    fishPlugins.bass

    # # Disk utils
    # ventoy-full

    # Spotify
    spotify
    spicetify-cli
    # spotify-tui
    # spotifyd

    # Browsers
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

    # # VS Code
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

    # Other Programs
    stremio
    obsidian

    # VPN software
    protonvpn-cli
    protonvpn-gui
    cloudflare-warp
    wgcf

  ];

}
