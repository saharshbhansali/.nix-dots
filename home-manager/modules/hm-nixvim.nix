{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{

  imports = [
    inputs.nixvim.homeModules.nixvim
    # inputs.nixCatsNvim.homeModules.default
  ];

  programs.nixvim = {
    enable = true;

    clipboard.register = "unnamedplus";
    clipboard.providers.wl-copy.enable = true;
    clipboard.providers.xclip.enable = true;

    colorschemes.catppuccin.enable = true;

    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;

    # plugins = {
    #   lazy.enable = true;
    #
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
    #
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

  ## User level packages
  home.packages = with pkgs; [
    inputs.nixCatsNvim.packages.${pkgs.system}.cats-vim
    # inputs.nixCatsNvim.packages.${pkgs.system}.nvim
    # inputs.nixCatsNvim.packages.${pkgs.system}.testnvim
    universal-ctags
    curl
    # NOTE:
    # lazygit
    # Apparently lazygit when launched via snacks cant create its own config file
    # but we can add one from nix!
    (pkgs.writeShellScriptBin "lazygit" ''
      exec ${pkgs.lazygit}/bin/lazygit --use-config-file ${pkgs.writeText "lazygit_config.yml" ""} "$@"
    '')
    ripgrep
    fd
    stdenv.cc.cc
    lua-language-server
    nil # I would go for nixd but lazy chooses this one idk
    stylua
    fzf
    # --- LSP plugins ---
    tree-sitter
    black
    prettier
    ruff
    dockerfile-language-server
    gopls
    jdt-language-server
    rust-analyzer
    yaml-language-server
    tailwindcss-language-server
    typescript-language-server
    sqls
    texlab
    taplo
    marksman
    nil
    nixfmt
    lua51Packages.lua
    # lua51Packages.luarocks
    lua51Packages.luarocks-nix
    lua51Packages.fzf-lua

    vimPlugins.LazyVim
    # vimPlugins.lazy-nvim
    # vimPlugins.bufferline-nvim
    # vimPlugins.lazydev-nvim
    # vimPlugins.conform-nvim
    # vimPlugins.flash-nvim
    # vimPlugins.friendly-snippets
    # vimPlugins.gitsigns-nvim
    # vimPlugins.grug-far-nvim
    # vimPlugins.aerial-nvim
    # vimPlugins.none-ls-nvim
    # vimPlugins.noice-nvim
    # vimPlugins.lualine-nvim
    # vimPlugins.nui-nvim
    # vimPlugins.nvim-lint
    # vimPlugins.nvim-lspconfig
    # vimPlugins.nvim-ts-autotag
    # vimPlugins.ts-comments-nvim
    # vimPlugins.blink-cmp
    # vimPlugins.blink-compat
    # vimPlugins.nvim-web-devicons
    # vimPlugins.persistence-nvim
    # vimPlugins.plenary-nvim
    # vimPlugins.telescope-fzf-native-nvim
    # vimPlugins.telescope-nvim
    # vimPlugins.todo-comments-nvim
    # vimPlugins.tokyonight-nvim
    # vimPlugins.trouble-nvim
    # vimPlugins.vim-illuminate
    # vimPlugins.vim-startuptime
    # vimPlugins.which-key-nvim
    # vimPlugins.snacks-nvim

    ## Treesitter
    # vimPlugins.nvim-treesitter-textobjects
    # vimPlugins.nvim-treesitter-context
    # vimPlugins.nvim-treesitter-pairs
    # vimPlugins.nvim-treesitter-endwise
    # vimPlugins.nvim-treesitter
    # vimPlugins.nvim-treesitter.withAllGrammars
    # This is for if you only want some of the grammars
    # (nvim-treesitter.withPlugins (
    #   plugins: with plugins; [
    #     nix
    #     lua
    #   ]
    # ))

    # vimPlugins.catppuccin-nvim
    # vimPlugins.CopilotChat-nvim
    # vimPlugins.supermaven-nvim
    # vimPlugins.mini-nvim
    # vimPlugins.mini-ai
    # vimPlugins.mini-icons
    # vimPlugins.mini-pairs
    # vimPlugins.mini-comment
    # vimPlugins.mini-snippets
    # vimPlugins.mini-surround
    # vimPlugins.mini-diff
    # vimPlugins.mini-files
    # vimPlugins.mini-move
    # vimPlugins.mini-git
    # vimPlugins.mini-extra
    # vimPlugins.mini-doc
    # vimPlugins.mini-indentscope
    # vimPlugins.mini-hipatterns
    # vimPlugins.neogen
    # vimPlugins.yanky-nvim
    # vimPlugins.dial-nvim
    # vimPlugins.harpoon2
    # vimPlugins.inc-rename-nvim
    # vimPlugins.leap-nvim
    # vimPlugins.outline-nvim
    # vimPlugins.overseer-nvim
    # vimPlugins.refactoring-nvim
    # vimPlugins.fzf-lua
    # vimPlugins.vim-prettier
    # vimPlugins.gitsigns-nvim
    # vimPlugins.go-nvim
    # vimPlugins.nvim-jdtls
    # vimPlugins.markdown-preview-nvim
    # vimPlugins.rustaceanvim
    # vimPlugins.tailwindcss-colors-nvim
    # vimPlugins.vimtex
    # vimPlugins.yaml-companion-nvim
    # vimPlugins.dashboard-nvim
    # vimPlugins.edgy-nvim
    # vimPlugins.indent-blankline-nvim
    # vimPlugins.project-nvim
    # vimPlugins.vim-repeat
    # vimPlugins.vim-startuptime
    # vimPlugins.venv-selector-nvim
    # vimPlugins.render-markdown-nvim
    # vimPlugins.litee-nvim
    # vimPlugins.telescope-github-nvim

    ## Language-related utilities
    # vimPlugins.vim-dadbod
    # vimPlugins.vim-dadbod-ui
    # vimPlugins.vim-dadbod-completion
  ];

  home.file.".config/nvim" = {
    source = ../../configs/nvim;
    recursive = true;
  };

  # # Test config for experimentation
  # home.file.".config/testnvim" = {
  #   source = ../../configs/nvim;
  #   recursive = true;
  #   # mutable = true;
  # };
  # home.activation.copyTestNvim = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   set -eu
  #
  #   target="$HOME/.config/testnvim"
  #   src=${../../configs/nvim}
  #
  #   mkdir -p "$HOME/.config"
  #
  #   if [ -e "$target" ]; then
  #     echo "Found existing $target — backing up before copying..."
  #     backup="/tmp/testnvim.backup-$(date +%Y%m%d-%H%M%S)"
  #     mv "$target" "$backup"
  #     echo "Backed up to $backup"
  #   fi
  #
  #   cp -r "$src" "$target"
  #   chmod -R ug+w "$target"
  #   echo "Copied Neovim config to $target"
  # '';

}
