{ config, pkgs, inputs, lib, ... }:

{

  imports = [ inputs.nixvim.nixosModules.nixvim ];

  programs.nixvim = {
    enable = true;
    colorschemes.catppuccin.enable = true;

    plugins = {
      lazy.enable = true;
      # lazy.plugins = with plugins; [
      #  # fzf-lua
      #  # harpoon2
      #  # dot
      #  # gitui
      # ];
      lsp = {
        enable = true;
        servers = {
          lua-ls.enable = true;
          rust-analyzer.enable = true;
        };
      };
      treesitter.enable = true;
      telescope.enable = true;
      which-key.enable = true;
      lualine.enable = true;      
      yanky.enable = true;        
      harpoon.enable = true;      
      telescope.enable = true;    
      mini.enable = true;         
      web-devicons.enable = true; 

    };

    # extraConfigLua = ''
    #   vim.opt.number = true
    #   vim.opt.relativenumber = true
    # '';
  };

}
