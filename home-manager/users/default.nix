{ config, pkgs, lib, inputs, nixpkgs, ... }:
# let
#   nixvim = inputs.nixvim.legacyPackages.${pkgs.system};
# in
{
  home.stateVersion = "24.11";

  home.username = "saharsh";
  home.homeDirectory = "/home/saharsh";


  # Starting user services via systemd
  systemd.user.startServices = true;


  # Since we do not install home-manager, you need to let home-manager
  # manage your shell, otherwise it will not be able to add its hooks
  # to your profile.
  programs.home-manager.enable = true;
  programs.zsh.enable = true;

  imports = [
    ../modules/hm-nixvim.nix
  ];
  # imports = [
  #   inputs.nixvim.homeManagerModules.nixvim
  # ];
  #
  # programs.nixvim = {
  #   enable = true;
  #
  #   clipboard.providers.wl-copy.enable = true;
  #
  #   colorschemes.catppuccin.enable = true;
  #
  #   plugins.lazy.enable = true;
  #
  #   plugins.lualine.enable = true;
  #   plugins.yanky.enable = true;
  #   plugins.harpoon.enable = true;
  #   plugins.telescope.enable = true;
  #   plugins.treesitter.enable = true;
  #   # plugins.nvim-treesitter-textobjects.enable = true;
  #   plugins.mini.enable = true;
  #   plugins.web-devicons.enable = true;
  #   plugins.fzf-lua.enable = true;
  #   # plugins.harpoon.enable = true;
  # };


  ## Install packages
  # nixpkgs.config.allowUnfree = true;

  # User level packages
  home.packages = with pkgs; [

    # Terminal programs
    chezmoi

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



  # Enable other programs
  programs.browserpass.enable = true;
  programs.ghostty.enable = true;
  programs.git.enable = true;

  #
  # ## Configure home-manager
  # home-manager.backupFileExtension = "hm.bak";
  #

  # # Set cursor configuration and theme

  # pointer cursor change in home manager
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
    hyprcursor.size = 20;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 20;
  };

  # Set environment variables for X and Wayland cursor settings
  home.sessionVariables = {
    EDITOR = "nvim";

    XCURSOR_THEME = "Catppuccin Mocha Mauve";
    XCURSOR_SIZE = "20";
    HYPRCURSOR_THEME = lib.mkForce "Catppuccin Mocha Mauve";
    HYPRCURSOR_SIZE = lib.mkForce "20";

    # QT_QPA_PLATFORMTHEME="kvantum";
  };


}
