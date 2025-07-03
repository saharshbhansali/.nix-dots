{ config, pkgs, lib, inputs, ... }:

let
  lazySpec = ''
    require("lazy").setup({
      spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
        { "williamboman/mason.nvim", enabled = false },
        { "williamboman/mason-lspconfig.nvim", enabled = false },
        { import = "plugins" },
        { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
      },
      defaults = { lazy = true },
      install = { missing = false },
      change_detection = { enabled = false },
      performance = {
        cache = { enabled = true },
        reset_packpath = false,
        rtp = { reset = false },
      }
    })
  '';

  treesitterParsers = pkgs.symlinkJoin {
    name = "nvim-treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
      lua c cpp python rust go nix bash zsh fish
      javascript typescript html css json
      java zig markdown
    ]).dependencies;
  };
in {
  imports = [inputs.nixvim.nixosModules.default];
  environment.systemPackages = with pkgs; [
    neovim
    # Language servers
    lua-language-server
    stylua
    python3Packages.python-lsp-server
    rust-analyzer
    gopls
    # jdtls
    clang-tools
    zls
    nixd
    bash-language-server
    typescript-language-server
    tailwindcss-language-server
    marksman
    # Dev tools
    ripgrep
    fzf
  ];

  # # Neovim init.lua
  # environment.etc."nvim/init.lua".text = lazySpec;

  # Optional: mount your own custom Lua config directory
  environment.etc."nvim".source = ../../configs/nvim;

  # Treesitter parser binaries
  # environment.etc."nvim/parser".source = "${treesitterParsers}/parser";

  # Let Neovim know where to look for config if needed
  # environment.variables.XDG_CONFIG_DIRS = [ "/etc" ];
}
