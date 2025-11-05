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
  home.packages = {
    general = with pkgs; [
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
      lua51Packages.luarocks
      lua51Packages.luarocks-nix
      lua51Packages.fzf-lua
    ];
    plugin = with pkgs.vimPlugins; [
      lazy-nvim
      LazyVim
      bufferline-nvim
      lazydev-nvim
      conform-nvim
      flash-nvim
      friendly-snippets
      gitsigns-nvim
      grug-far-nvim
      aerial-nvim
      none-ls-nvim
      noice-nvim
      # lualine-nvim
      nui-nvim
      nvim-lint
      nvim-lspconfig
      nvim-ts-autotag
      ts-comments-nvim
      blink-cmp
      blink-compat
      nvim-web-devicons
      persistence-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-nvim
      todo-comments-nvim
      tokyonight-nvim
      trouble-nvim
      vim-illuminate
      vim-startuptime
      which-key-nvim
      snacks-nvim
      nvim-treesitter-textobjects
      nvim-treesitter-context
      nvim-treesitter-pairs
      nvim-treesitter-endwise
      nvim-treesitter
      nvim-treesitter.withAllGrammars
      # This is for if you only want some of the grammars
      # (nvim-treesitter.withPlugins (
      #   plugins: with plugins; [
      #     nix
      #     lua
      #   ]
      # ))

      # sometimes you have to fix some names
      {
        plugin = catppuccin-nvim;
        name = "catppuccin";
      }
      # you could do this within the lazy spec instead if you wanted
      # and get the new names from `:NixCats pawsible` debug command

      CopilotChat-nvim
      supermaven-nvim
      mini-nvim
      mini-ai
      mini-icons
      mini-pairs
      mini-comment
      mini-snippets
      mini-surround
      mini-diff
      mini-files
      mini-move
      mini-git
      mini-extra
      mini-doc
      mini-indentscope
      mini-hipatterns
      neogen
      yanky-nvim
      dial-nvim
      harpoon2
      inc-rename-nvim
      leap-nvim
      outline-nvim
      overseer-nvim
      refactoring-nvim
      fzf-lua
      pkgs.black
      vim-prettier
      gitsigns-nvim
      go-nvim
      nvim-jdtls
      markdown-preview-nvim
      # rustaceanvim
      tailwindcss-colors-nvim
      vimtex
      yaml-companion-nvim
      dashboard-nvim
      edgy-nvim
      indent-blankline-nvim
      # project-nvim
      vim-repeat
      vim-startuptime
      venv-selector-nvim
      render-markdown-nvim
      litee-nvim
      telescope-github-nvim

      # Language-related utilities
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
    ];
  };

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
