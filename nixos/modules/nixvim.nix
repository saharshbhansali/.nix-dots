{ config, pkgs, inputs, lib, ... }:

{
  imports = [ inputs.nixvim.nixosModules.nixvim ];

  programs.nixvim = {
    enable = true;

    clipboard.register = "unnamedplus";
    clipboard.providers.wl-copy.enable = true;

    colorschemes.catppuccin.enable = true;

    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;

    plugins = {
      lazy.enable = true;

      lsp = {
        enable = true;
        servers = {
          lua_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
        };
      };

      treesitter.enable = true;
      which-key.enable = true;
      lualine.enable = true;
      yanky.enable = true;
      harpoon.enable = true;
      telescope.enable = true;
      mini.enable = true;
      web-devicons.enable = true;
    };

    # extraLuaConfig = ''
    #   require("lazy").setup({
    #     -- your plugin specifications here
    #   })
    # '';

  };

  environment.systemPackages = with pkgs.vimPlugins; [
    LazyVim
    # neovim
    # neovim-remote
    # nvim-lspconfig
    # nvim-treesitter
    # which-key
    # lualine
    # yanky
    # harpoon
    # telescope
    # mini
    # web-devicons
  ];

}
