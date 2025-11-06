{ config, lib, pkgs, inputs, ... }:

{

  imports = [ 
    inputs.nixvim.homeModules.nixvim
    inputs.nixCatsNvim.homeModules.default
  ];

  ## User level packages
  home.packages = with pkgs; [
    # inputs.nixCatsNvim.packages.${pkgs.system}.nvim
    inputs.nixCatsNvim.packages.${pkgs.system}.testnvim
    inputs.nixCatsNvim.packages.${pkgs.system}.catsnvim
    inputs.nixPatchNvim.packages.${pkgs.system}.default
  ];

  # Config files for nixCatsNvim
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

  ## NixVim
  programs.nixvim = {
    enable = true;
  
    clipboard = {
      register = "unnamedplus";
      providers = {
        wl-copy.enable = true;
        xclip.enable = true;
      };
    };

    colorschemes.catppuccin.enable = true;

    viAlias = true;
    vimAlias = true;
    luaLoader.enable = true;

    plugins = {
      lazy.enable = true;

      # Core LSP and related tools
      lsp = {
        enable = true;
        servers = {
          lua_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
          jdtls.enable = true;
          yamlls.enable = true;
          tailwindcss.enable = true;
        };
      };

      none-ls = {
        enable = true;
        sources.formatting.black.enable = true;
      };
      nvim-lint.enable = true;

      treesitter = {
        enable = true;
        withAllGrammars = true;
        textobjects.enable = true;
        context.enable = true;
        pairs.enable = true;
        endwise.enable = true;
      };

      which-key.enable = true;
      lualine.enable = true;
      yanky.enable = true;
      harpoon.enable = true;
      telescope = {
        enable = true;
        fzf-native.enable = true;
        github.enable = true;
      };

      mini = {
        enable = true;
        ai.enable = true;
        comment.enable = true;
        diff.enable = true;
        files.enable = true;
        git.enable = true;
        pairs.enable = true;
        snippets.enable = true;
        surround.enable = true;
        indentscope.enable = true;
        move.enable = true;
        extra.enable = true;
        hipatterns.enable = true;
        doc.enable = true;
        icons.enable = true;
      };

      web-devicons.enable = true;
      flash.enable = true;
      alpha.enable = true;
      bufferline.enable = true;
      conform-nvim.enable = true;
      friendly-snippets.enable = true;
      gitsigns.enable = true;
      todo-comments.enable = true;
      trouble.enable = true;
      noice.enable = true;
      nui.enable = true;
      aerial.enable = true;
      outline.enable = true;
      edgy.enable = true;
      snacks.enable = true;
      persistence.enable = true;
      overseer.enable = true;
      neogen.enable = true;
      dial.enable = true;
      inc-rename.enable = true;
      leap.enable = true;
      refactoring.enable = true;
      illuminate.enable = true;
      dashboard.enable = true;
      indent-blankline.enable = true;
      vimtex.enable = true;
      markdown-preview.enable = true;
      venv-selector.enable = true;
      render-markdown.enable = true;
      litee.enable = true;
      vim-dadbod = {
        enable = true;
        ui.enable = true;
        completion.enable = true;
      };

      # External integrations
      copilot-chat.enable = true;
      supermaven.enable = true;
      blink-cmp.enable = true;
      prettier.enable = true;
      rustacean.enable = true;
      dap-go.enable = true;
      fzf-lua.enable = true;
    };
  };

}
