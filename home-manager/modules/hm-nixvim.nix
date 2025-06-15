{ config, lib, pkgs, inputs, ... }:

{

  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  programs.nixvim = {
    enable = true;

    clipboard.register = "unnamedplus";
    clipboard.providers.wl-copy.enable = true;
    clipboard.providers.xclip.enable = true;

    colorschemes.catppuccin.enable = true;

    # plugins = {
    #   lazy.enable = true;

    #   lsp = {
    #     enable = true;
    #     servers = {
    #       lua_ls.enable = true;
    #       rust_analyzer = {
    #         enable = true;
    #         installCargo = true;
    #         installRustc = true;
    #       };
    #     };
    #   };

    #   treesitter.enable = true;
    #   which-key.enable = true;
    #   lualine.enable = true;
    #   yanky.enable = true;
    #   harpoon.enable = true;
    #   telescope.enable = true;
    #   mini.enable = true;
    #   web-devicons.enable = true;
    # };
  };

}
