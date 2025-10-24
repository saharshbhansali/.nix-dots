{ config, lib, pkgs, inputs, ... }:
let
  # Apply the customization patch to oh-my-tmux's tmux.conf.local using tmux/customize-omt.patch and tmux/tmux.conf.local symlink

  # Directory paths relative to this Nix file
  tmuxDir = ../../configs/tmux;
  ohMyTmuxSrc = ../../configs/oh-my-tmux;

  # Apply your patch to the git submodule source
  patchedOhMyTmux = pkgs.runCommandLocal "oh-my-tmux-patched" {} ''
    mkdir -p $out
    cp -rT ${ohMyTmuxSrc} $out
    patch -d $out -p1 < ${tmuxDir}/customize-omt.patch
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

  home.file.".config/nvim" = {
    source = ../../configs/nvim;
    recursive = true;
  };

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

  home.file.".config/atuin/config.toml".source = ../../configs/atuin/config.toml;
  home.file.".config/pay-respects/config.toml".source = ../../configs/pay-respects/config.toml;

  home.file.".config/libinput-gestures.conf".source = ../../configs/libinput-gestures.conf;

  home.file.".config/konsave/kde-profile.knsv".source = ../../configs/konsave/kde-profile.knsv;
  home.file.".config/konsave/keyboard-shortcuts.kksrc".source = ../../configs/konsave/keyboard-shortcuts.kksrc;

  home.file.".newsboat/urls".source = ../../configs/newsboat/urls;

}
