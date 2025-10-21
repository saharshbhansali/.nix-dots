{ config, lib, pkgs, inputs, ... }:

{

  programs = {

    # zsh.enable = true;
    # fish.enable = true;
    # starship.enable = true;
    direnv = {
      enable = true;
      # enableBashIntegration = true; # see note on other shells below
      # enableZshIntegration = true; # see note on other shells below
      # enableFishIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };

    carapace.enable = true;

    starship = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      # settings = {
      #   add_newline = true;
      #   character = {
      #     success_symbol = "[➜](bold green)";
      #     error_symbol = "[➜](bold red)";
      #   };
      # };
    };

  };


  ## User level packages
  home.packages = with pkgs; [

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

  ];

}
