{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # dotfilesDir = "/path/to/dotfiles";
  # dotfilesDir = "$HOME/.config/.nix-dots";
  # Apply the customization patch to oh-my-tmux's tmux.conf.local using tmux/customize-omt.patch and tmux/tmux.conf.local symlink
  # Directory paths relative to this Nix file
  tmuxDir = ../../configs/tmux;
  ohMyTmuxSrc = ../../configs/oh-my-tmux;

  # Apply your patch to the git submodule source
  patchedOhMyTmux = pkgs.runCommandLocal "oh-my-tmux-patched" {} ''
    mkdir -p $out
    cp -rT ${ohMyTmuxSrc} $out
    chmod a+w $out/.tmux.conf.local
    patch -d $out -p1 < ${tmuxDir}/customize-omt.patch
    chmod a-w $out/.tmux.conf.local
  '';
in {
  # Configure programs
  home.file.".zshrc".source = ../../configs/zsh/.zshrc;
  home.file.".p10k.zsh".source = ../../configs/zsh/.p10k.zsh;
  xdg.configFile."ohmyzsh-custom" = {
    source = ../../configs/zsh/ohmyzsh-custom;
    recursive = true;
  };

  xdg.configFile."fish/config.fish".source = ../../configs/fish/config.fish;

  # xdg.configFile."nvim" = {
  #   source = ../../configs/nvim;
  #   recursive = true;
  # };

  # Your tmux directory (contains patch + symlink)
  xdg.configFile."tmux" = {
    source = tmuxDir;
    recursive = true;
  };

  # Use patched oh-my-tmux as the source
  xdg.configFile."oh-my-tmux" = {
    source = patchedOhMyTmux;
    recursive = true;
  };

  xdg.configFile."tmux-which-key" = {
    source = ../../configs/tmux-which-key;
    recursive = true;
  };

  xdg.configFile."kitty" = {
    source = ../../configs/kitty;
    recursive = true;
  };

  xdg.configFile."ghostty" = {
    source = ../../configs/ghostty;
    recursive = true;
  };

  xdg.configFile."zellij" = {
    source = ../../configs/zellij;
    recursive = true;
  };

  xdg.configFile."wezterm" = {
    source = ../../configs/wezterm;
    recursive = true;
  };

  xdg.configFile."atuin/config.toml".source = ../../configs/atuin/config.toml;
  xdg.configFile."pay-respects/config.toml".source = ../../configs/pay-respects/config.toml;

  xdg.configFile."libinput-gestures.conf".source = ../../configs/gestures/libinput-gestures.conf;
  xdg.configFile."gestures/alt_tab_switcher" = {
    source = ../../configs/gestures/alt_tab_switcher;
    recursive = true;
  };

  xdg.configFile."konsave/kde-profile.knsv".source = ../../configs/konsave/kde-profile.knsv;
  xdg.configFile."konsave/keyboard-shortcuts.kksrc".source =
    ../../configs/konsave/keyboard-shortcuts.kksrc;

  home.file."configs/vicinae/settings.json".source = ../../configs/vicinae/settings.json;

  home.file."searxng/core-config" = {
    source = ../../configs/searxng;
    recursive = true;
  };

  home.file.".newsboat" = {
    source = ../../configs/newsboat;
    recursive = true;
  };

  home.file.".newsboat/dark".source = builtins.fetchurl {
    # url = "https://raw.githubusercontent.com/catppuccin/newsboat/main/themes/dark";
    # sha256 = lib.fakeSha256;
    url = "https://github.com/catppuccin/newsboat/raw/be3d0ee1ba0fc26baf7a47c2aa7032b7541deb0f/themes/dark";
    sha256 = "sha256:09x50g74mld8zv8r6a873j52zx3w86qv3mc7g4fhzr85911cz799";
  };

  home.file.".links/links.cfg".source = ../../configs/links/links.cfg;
  xdg.configFile."elinks/elinks.conf".source = ../../configs/elinks/elinks.conf;
  home.file.".w3m/keymap".source = ../../configs/w3m/keymap;

  # home.file.".links/links.cfg".text = builtins.readFile ../../configs/links/links.cfg;
  # xdg.configFile."elinks/elinks.conf".text = builtins.readFile ../../configs/elinks/elinks.conf;

  # home.activation.make-symlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   # Create the directories
  #   mkdir -p $HOME/.links
  #   mkdir -p $HOME/.config/elinks
  #
  #   # Make symlinks to the dotfiles
  #   ln -sf ${dotfilesDir}/configs/links/links.cfg $HOME/.links/links.cfg
  #   ln -sf ${dotfilesDir}/configs/elinks/elinks.conf $HOME/.config/elinks/elinks.conf
  # '';
}
