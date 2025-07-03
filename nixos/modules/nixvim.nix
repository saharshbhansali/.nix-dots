{ config, lib, pkgs, ... }:

let 
  vimPkgs = pkgs.vimPlugins;
  lazyPlugins = with vimPkgs; [
    lazy-nvim
    nvim-treesitter
  ];

  lazySpec = ''
    require("lazy").setup({
      defaults = { lazy = true },
      install = { missing = false },
      change_detection = { enabled = false },
      performance = { packpath = { reset = false }, rtp = { reset = false } },
      spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
        { "williamboman/mason-lspconfig.nvim", enabled = false },
        { "williamboman/mason.nvim", enabled = false },
        -- Your extra plugins here
      },
    })
  '';

  treesitterParsers = pkgs.symlinkJoin {
    name = "nvim-treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };

in {
  environment.systemPackages = with pkgs; [
    neovim
    lua-language-server
    stylua
    ripgrep
    python3Packages.python-lsp-server
    rust-analyzer
    gopls
    bash-language-server
    typescript-language-server
    tailwindcss-language-server
    zig
    zls
    # add more if needed
  ];

  # This mounts lazy.nvim and any other plugins you want preloaded
  environment.etc."nvim/init.lua".source = ../../configs/nvim;
  environment.etc."nvim/lazy-lock.json".source = ../../configs/nvim/lazy-lock.json;
  environment.etc."nvim/lazyvim.json".source = ../../configs/nvim/lazyvim.json;
  environment.etc."nvim/stylua.toml".source = ../../configs/nvim/stylua.toml;
  environment.etc."nvim/lua/plugins/mini-plugins.lua".source = ../../configs/nvim/lua/plugins/mini-plugins.lua;
  environment.etc."nvim/lua/plugins/theme.lua".source = ../../configs/nvim/lua/plugins/theme.lua;
  environment.etc."nvim/lua/plugins/example.lua".source = ../../configs/nvim/lua/plugins/example.lua;
  environment.etc."nvim/lua/config/lazy.lua".source = ../../configs/nvim/lua/config/lazy.lua;
  environment.etc."nvim/lua/config/autocmds.lua".source = ../../configs/nvim/lua/config/autocmds.lua;
  environment.etc."nvim/lua/config/keymaps.lua".source = ../../configs/nvim/lua/config/keymaps.lua;
  environment.etc."nvim/lua/config/options.lua".source = ../../configs/nvim/lua/config/options.lua;
  environment.etc."nvim/lua/config/transparency.lua".source = ../../configs/nvim/lua/config/transparency.lua;

  # This adds Treesitter parser .so files to XDG_CONFIG_HOME/nvim/parser
  # xdg.configFile."nvim/parser".source = "${treesitterParsers}/parser";

  # Optional: mount your `lua/` config
  # xdg.configFile."nvim/lua".source = ./lua;
}
