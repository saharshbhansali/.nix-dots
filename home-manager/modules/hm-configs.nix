{ config, lib, pkgs, inputs, ... }:

{

  # Configure programs
  home.file.".zshrc".source = ../../configs/zsh/.zshrc;
  home.file.".config/ohmyzsh-custom" = {
    source = ../../configs/zsh/ohmyzsh-custom;
    recursive = true;
  };

  home.file.".config/nvim" = {
    source = ../../configs/nvim;
    recursive = true;
  };

  home.file.".config/kitty" = {
    source = ../../configs/kitty;
    recursive = true;
  };

  home.file.".config/atuin/config.toml".source = ../../configs/atuin/config.toml;

}
