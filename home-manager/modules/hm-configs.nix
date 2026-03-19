{ config, lib, pkgs, inputs, ... }:
let
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
in
{

  # Configure programs
  home.file.".zshrc".source = ../../configs/zsh/.zshrc;
  home.file.".p10k.zsh".source = ../../configs/zsh/.p10k.zsh;
  home.file.".config/ohmyzsh-custom" = {
    source = ../../configs/zsh/ohmyzsh-custom;
    recursive = true;
  };

  home.file.".config/fish/config.fish".source = ../../configs/fish/config.fish;

  # home.file.".config/nvim" = {
  #   source = ../../configs/nvim;
  #   recursive = true;
  # };

  # Your tmux directory (contains patch + symlink)
  home.file.".config/tmux" = {
    source = tmuxDir;
    recursive = true;
  };

  # Use patched oh-my-tmux as the source
  home.file.".config/oh-my-tmux" = {
    source = patchedOhMyTmux;
    recursive = true;
  };

  home.file.".config/kitty" = {
    source = ../../configs/kitty;
    recursive = true;
  };

  home.file.".config/ghostty" = {
    source = ../../configs/ghostty;
    recursive = true;
  };

  home.file.".config/zellij" = {
    source = ../../configs/zellij;
    recursive = true;
  };

  home.file.".config/wezterm" = {
    source = ../../configs/wezterm;
    recursive = true;
  };

  home.file.".config/atuin/config.toml".source = ../../configs/atuin/config.toml;
  home.file.".config/pay-respects/config.toml".source = ../../configs/pay-respects/config.toml;

  home.file.".config/libinput-gestures.conf".source = ../../configs/gestures/libinput-gestures.conf;
  home.file.".config/gestures/alt_tab_switcher" = {
    source = ../../configs/gestures/alt_tab_switcher;
    recursive = true;
  };

  home.file.".config/konsave/kde-profile.knsv".source = ../../configs/konsave/kde-profile.knsv;
  home.file.".config/konsave/keyboard-shortcuts.kksrc".source = ../../configs/konsave/keyboard-shortcuts.kksrc;

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
  home.file.".config/elinks/elinks.conf".source = ../../configs/elinks/elinks.conf;
  home.file.".w3m/keymap".source = ../../configs/w3m/keymap;

  # home.file.".links/links.cfg".text = builtins.readFile ../../configs/links/links.cfg;
  # home.file.".config/elinks/elinks.conf".text = builtins.readFile ../../configs/elinks/elinks.conf;

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
