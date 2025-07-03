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
  environment.etc."nvim/init.lua".text = lazySpec;

  # This adds Treesitter parser .so files to XDG_CONFIG_HOME/nvim/parser
  # xdg.configFile."nvim/parser".source = "${treesitterParsers}/parser";

  # Optional: mount your `lua/` config
  # xdg.configFile."nvim/lua".source = ./lua;
}
