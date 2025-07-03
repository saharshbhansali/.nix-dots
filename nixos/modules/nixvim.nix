{ config, pkgs, inputs, ... }:

let
  # Define a symlink-join of selected treesitter parsers for supported languages
  treesitterParsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
      c      cpp  # C/C++
      lua    python  go  rust  # core languages
      nix    bash  fish   # shell, nix
      javascript typescript html css json  # web, ts
      zig   # Zig
      markdown  # Markdown
      # (tailwind itself is handled via LSP: no parser needed)
    ])).dependencies;
  };
in {
  imports = [ inputs.nixvim.nixosModules.nixvim ];
  options = {
    # (no custom options defined; we rely on nixvim defaults)
  };
  config = {
    programs.nixvim = {
      enable = true;
      # Ensure nvim uses our generated config:
      wrapRc = true;  

      # Install extra system packages (LSP servers, formatters, etc.) 
      # instead of using Mason runtime installs:
      extraPackages = with pkgs; [
        lua-language-server  # for Lua
        pyright             # Python LSP (or pyrefly)
        rust-analyzer       # Rust
        gopls               # Go
        clang-tools         # includes clangd for C/C++
        zig                 # Zig (LSP comes with zig)
        nix               # (nix environment)
        bash-language-server  # Bash
        typescript-language-server  # TypeScript
        tailwindcss-language-server  # Tailwind CSS
        marksman            # Markdown LSP
        # + any needed formatters e.g. prettier, stylua, etc.
        stylua             # Lua formatter
        pre-commit         # for Python linting (optional)
        fzf                # fzf native (for fzf.nvim)
      ];

      # Use nixvim's module system to enable plugins:
      # (E.g. nvim-lspconfig, treesitter, cmp, etc. as provided by nixvim)
      plugins = {
        lazy.enable = true;        # LazyVim plugin manager
        # nvim-treesitter.enable = true;
        # nvim-lspconfig.enable = true;  # Core LSP plugin
        # nvim-cmp.enable = true;        # Completion engine
        # Additional plugins can be enabled via nixvim modules if available...
      };

      # If a plugin module does not exist in nixvim, use extraPlugins:
      # e.g. one might add `vim-nix` for Nix support if needed.
      extraPlugins = with pkgs.vimPlugins; [
        # e.g. vim-nix for Nix filetype highlighting, etc.
        vim-nix
      ];

      # Treesitter configuration (ensure the above languages are installed)
      # This generates the `parser` directory via nix_symlinkJoin:
      # xdg.configFile."nvim/parser".source = "${treesitterParsers}/parser";

      # The actual Lua config for LazyVim (using lazy.nvim):
      extraConfigLua = ''
        -- Initialize lazy.nvim with LazyVim plugin specs
        require("lazy").setup({
          spec = {
            -- Import LazyVim core plugins:
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            -- Ensure fzf-native (Telescope) is enabled (needed on Nix to enable the compiled C plugin):
            { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
            -- Disable Mason and mason-lspconfig (we use Nix for LSP installs):
            { "williamboman/mason.nvim", enabled = false },
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            -- (Import any user-supplied LazyVim plugin specs):
            { import = "plugins" },
            -- Override nvim-treesitter to avoid LazyVim auto-installs (we manage via nix):
            { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
          }
        })
      '';

      # Allow dropping custom Lua config files via XDG (e.g. lua/ directory in flake)
      # This lets the user provide additional lua config with `xdg.configFile`.
      # xdg.configFile."nvim/lua".source = ./lua;
    };
  };
}
