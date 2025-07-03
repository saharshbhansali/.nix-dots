{ config, lib, pkgs, inputs, ... }:

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

  home.file.".config/kitty" = {
    source = ../../configs/kitty;
    recursive = true;
  };

  home.file.".config/atuin/config.toml".source = ../../configs/atuin/config.toml;
  home.file.".config/pay-respects/config.toml".source = ../../configs/pay-respects/config.toml;

  home.file.".config/libinput-gestures.conf".source = ../../configs/libinput-gestures.conf;

  home.file.".config/konsave/conf.yaml".source = ../../configs/konsave/conf.yaml;
  home.file.".config/konsave/profiles/kde-profile" = {
    source = ../../configs/konsave/kde-profile;
    recursive = true;
  };

}
