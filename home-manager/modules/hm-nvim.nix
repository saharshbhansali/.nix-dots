{ config, lib, pkgs, inputs, ... }:

{

  imports = [
    inputs.nixvim.homeModules.nixvim
    inputs.nixCatsNvim.homeModules.default
  ];

  ## User level packages
  home.packages = with pkgs; [
    inputs.nixCatsNvim.packages.${pkgs.stdenv.hostPlatform.system}.nvim
    inputs.nixCatsNvim.packages.${pkgs.stdenv.hostPlatform.system}.testnvim
    # inputs.nixCatsNvim.packages.${pkgs.stdenv.hostPlatform.system}.catsnvim
    # inputs.nixPatchNvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    vimPlugins.nvim-treesitter.withAllGrammars
    # vimPlugins.nvim-treesitter
  ];

  # # Config files for nixCatsNvim
  # home.file.".config/LazyVim" = {
  #   source = ../../configs/nvim;
  #   recursive = true;
  # };

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

  # ## NixVim
  # programs.nixvim = {
  #   enable = true;
  #
  #   nixpkgs = {
  #     config = {
  #       allowUnfree = true;
  #     };
  #   };
  #
  #   clipboard.register = "unnamedplus";
  #   clipboard.providers.wl-copy.enable = true;
  #   clipboard.providers.xclip.enable = true;
  #
  #   colorschemes.catppuccin = {
  #     enable = true;
  #     autoLoad = true;
  #     settings = {
  #       flavour = "mocha";
  #       transparent_background = true;
  #       term_colors = true;
  #       default_integrations = true;
  #       integrations = {
  #         aerial = true;
  #         alpha = true;
  #         cmp = true;
  #         dashboard = true;
  #         flash = true;
  #         fzf = true;
  #         grug_far = true;
  #         gitsigns = true;
  #         headlines = true;
  #         illuminate = true;
  #         indent_blankline = true;
  #         leap = true;
  #         lsp_trouble = true;
  #         mason = true;
  #         mini = true;
  #         # navic = { enabled = true; custom_bg = "lualine" };
  #         navic = true;
  #         neotest = true;
  #         neotree = true;
  #         noice = true;
  #         notify = true;
  #         snacks = true;
  #         telescope = true;
  #         treesitter_context = true;
  #         which_key = true;
  #       };
  #     };
  #   };
  #
  #   viAlias = true;
  #   vimAlias = true;
  #
  #   luaLoader.enable = true;
  #
  #   # extraConfigLua = ''
  #   #   -- Disable Mason and mason-lspconfig
  #   #   require("lazy").setup({
  #   #     { 'williamboman/mason.nvim', enabled = false },
  #   #     { 'williamboman/mason-lspconfig.nvim', enabled = false },
  #   #     {
  #   #       'nvim-treesitter/nvim-treesitter',
  #   #       run = ':TSUpdate', -- Ensure parsers are updated
  #   #       config = function()
  #   #         require('nvim-treesitter.configs').setup {
  #   #           ensure_installed = {}, -- Disabled
  #   #           indent = { enable = true }, ---@type lazyvim.TSFeat
  #   #           highlight = { enable = true }, ---@type lazyvim.TSFeat
  #   #           folds = { enable = true }, ---@type lazyvim.TSFeat
  #   #         }
  #   #       end,
  #   #     },
  #   #   }, {})
  #   # '';
  #
  #   plugins = {
  #     # LazyVim
  #     # lazy.enable = true;
  #     # LazyVim.enable = true;
  #
  #     # UI-related plugins
  #     alpha.enable = true;
  #     alpha.theme = "dashboard";
  #
  #     # LSP and Completion
  #     lsp.enable = true;
  #     lsp.servers = {
  #       astro.enable = true;
  #       bashls.enable = true;
  #       basedpyright.enable = true;
  #       clangd.enable = true;
  #       cmake.enable = true;
  #       copilot.enable = true;
  #       docker_compose_language_service.enable = true;
  #       dockerls.enable = true;
  #       docker_language_server.enable = true;
  #       eslint.enable = true;
  #       gopls.enable = true;
  #       jsonls.enable = true;
  #       markdown_oxide.enable = true;
  #       marksman.enable = true;
  #       nginx_language_server.enable = true;
  #       nil_ls.enable = true;
  #       postgres_lsp.enable = true;
  #       # pyre.enable = true;
  #       pyrefly.enable = true;
  #       pyright.enable = true;
  #       ruff.enable = true;
  #       # ruff_lsp.enable = true;
  #       yamlls.enable = true;
  #       lua_ls.enable = true;
  #       rust_analyzer.enable = true;
  #       rust_analyzer.installCargo = true;
  #       rust_analyzer.installRustc = true;
  #       rust_analyzer.installRustfmt = true;
  #       # snyk_ls.enable = true;
  #       sqls.enable = true;
  #       stylua.enable = true;
  #       systemd_ls.enable = true;
  #       tailwindcss.enable = true;
  #       texlab.enable = true;
  #       ts_ls.enable = true;
  #       tsgo.enable = true;
  #     };
  #
  #     # Treesitter
  #     # cmp-treesitter.enable = true;
  #     treesitter-textobjects.enable = true;
  #     treesitter-context.enable = true;
  #     # treesitter-pairs.enable = true;
  #     treesitter-refactor.enable = true;
  #     ts-autotag.enable = true;
  #     treesitter = {
  #       enable = true;
  #       settings = {
  #         auto_install = false;
  #         ensure_installed = [ "all" ];
  #         highlight = {
  #           enable = true;
  #           additional_vim_regex_highlighting = true;
  #           custom_captures = { };
  #           # disable = [
  #           #   "rust"
  #           # ];
  #         };
  #         # ignore_install = [
  #         #   "rust"
  #         # ];
  #         incremental_selection = {
  #           enable = true;
  #           # keymaps = {
  #           #   init_selection = false;
  #           #   node_decremental = "grm";
  #           #   node_incremental = "grn";
  #           #   scope_incremental = "grc";
  #           # };
  #         };
  #         indent = {
  #           enable = true;
  #         };
  #         # parser_install_dir = {
  #         #   __raw = "vim.fs.joinpath(vim.fn.stdpath('data'), 'treesitter')";
  #         # };
  #         sync_install = false;
  #       };
  #     };
  #
  #     ## LazyVim setup
  #     # Core Plugins
  #     mini-pairs.enable = true;
  #     ts-comments.enable = true;
  #     mini-ai.enable = true;
  #     lazydev.enable = true;
  #     # Colorscheme
  #     bufferline.enable = true;
  #     # Editor
  #     grug-far.enable = true;
  #     flash.enable = true;
  #     which-key.enable = true;
  #     which-key.autoLoad = true;
  #     gitsigns.enable = true;
  #     trouble.enable = true;
  #     todo-comments.enable = true;
  #     # Formatting and Linting
  #     conform-nvim.enable = true; # Needs a bit of configuration
  #     lint.enable = true;
  #     # LSP
  #     # lspconfig.enable = true;
  #     # TreeSitter
  #     # treesitter.enable = true;
  #     # UI
  #     # bufferline.enable = true;
  #     lualine.enable = true;
  #     noice.enable = true;
  #     mini-icons.enable = true;
  #     nui.enable = true;
  #     snacks.enable = true;
  #     # Util
  #     persistence.enable = true;
  #     # plenary.enable = true;
  #
  #     # # Which Key and UI Enhancements
  #     # which-key.enable = true;
  #     # which-key.autoLoad = true;
  #     # lualine.enable = true;
  #     web-devicons.enable = true;
  #     # noice.enable = true;
  #     # trouble.enable = true;
  #     #
  #     # Snippet-related
  #     luasnip.enable = true;
  #     friendly-snippets.enable = true;
  #
  #     # QoL Integration
  #     # gitsigns.enable = true;
  #     yanky.enable = true;
  #     harpoon.enable = true;
  #
  #     # Telescope
  #     telescope.enable = true;
  #     telescope.extensions.advanced-git-search.enable = true;
  #     telescope.extensions.file-browser.enable = true;
  #     telescope.extensions.fzf-native.enable = true;
  #     telescope.extensions.project.enable = true;
  #     telescope.extensions.ui-select.enable = true;
  #     telescope.extensions.undo.enable = true;
  #
  #     # # Mini Plugins
  #     mini.enable = true;
  #     # mini-ai.enable = true;
  #     mini-basics.enable = true;
  #     mini-bracketed.enable = true;
  #     mini-clue.enable = true;
  #     mini-colors.enable = true;
  #     mini-comment.enable = true;
  #     mini-completion.enable = true;
  #     mini-cursorword.enable = true;
  #     mini-diff.enable = true;
  #     mini-doc.enable = true;
  #     mini-extra.enable = true;
  #     mini-files.enable = true;
  #     mini-fuzzy.enable = true;
  #     mini-git.enable = true;
  #     mini-hipatterns.enable = true;
  #     # mini-icons.enable = true;
  #     # mini-indentscope.enable = true;
  #     mini-jump.enable = true;
  #     # mini-jump2d.enable = true;
  #     mini-keymap.enable = true;
  #     # mini-misc.enable = true;
  #     mini-move.enable = true;
  #     mini-notify.enable = true;
  #     # mini-pairs.enable = true;
  #     # mini-pick.enable = true;
  #     # mini-sessions.enable = true;
  #     # mini-snippets.enable = true;
  #     # mini-starter.enable = true;
  #     mini-surround.enable = true;
  #     mini-tabline.enable = true;
  #
  #     # Neogen
  #     neogen.enable = true;
  #
  #     # Refactoring and code enhancements
  #     refactoring.enable = true;
  #     # inc-rename.enable = true;
  #
  #     # FZF and Search Enhancements
  #     fzf-lua.enable = true;
  #
  #     # Specific UI and Miscellaneous
  #     illuminate.enable = true;
  #     # startuptime.enable = true;
  #     # snacks.enable = true;
  #
  #     # Copilot and AI
  #     copilot-chat.enable = true;
  #     supermaven.enable = true;
  #
  #     # Other Plugins
  #     vim-visual-multi.enable = true;
  #     leap.enable = true;
  #     overseer.enable = true;
  #     # # tailwind-tools.enable = true;
  #     vimtex.enable = true;
  #     dashboard.enable = true;
  #     indent-blankline.enable = true;
  #     navic.enable = true;
  #
  #     # Project Management
  #     project-nvim.enable = true;
  #
  #     # Debugging/Markdown/Additional Support
  #     markdown-preview.enable = true;
  #     render-markdown.enable = true;
  #
  #     # Database interface for vim
  #     vim-dadbod.enable = true;
  #     vim-dadbod-ui.enable = true; # Enable UI for vim-dadbod
  #     vim-dadbod-completion.enable = true;
  #   };
  # };

}
