{ config, pkgs, inputs, ... }:
let
  nixvim = inputs.nixvim.legacyPackages.${pkgs.system};
in
{
  home.username = "saharsh";
  home.homeDirectory = "/home/saharsh";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  imports = [
    nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    colorschemes.catppuccin.enable = true;

    plugins = {
      treesitter.enable = true;
      lsp = {
        enable = true;
        servers = {
          lua-ls.enable = true;
          rust-analyzer.enable = true;
        };
      };
      telescope.enable = true;
      which-key.enable = true;
    };

    # extraConfigLua = ''
    #   vim.opt.number = true
    #   vim.opt.relativenumber = true
    # '';
  };

  home.packages = with pkgs; [
    zoxide eza fzf ripgrep tmux
  ];

  programs.zsh.enable = true;
  programs.git.enable = true;
}
