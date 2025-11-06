{ config, lib, pkgs, inputs, ... }:

{

  imports = [ 
    # inputs.nixvim.homeModules.nixvim
    inputs.nixCatsNvim.homeModules.default
  ];

  # programs.nixvim = {
  #   enable = true;
  #
  #   clipboard.register = "unnamedplus";
  #   clipboard.providers.wl-copy.enable = true;
  #   clipboard.providers.xclip.enable = true;
  #
  #   colorschemes.catppuccin.enable = true;
  #
  #   viAlias = true;
  #   vimAlias = true;
  #
  #   luaLoader.enable = true;
  #
  #   # plugins = {
  #   #   lazy.enable = true;
  #   #
  #   #   lsp = {
  #   #     enable = true;
  #   #     servers = {
  #   #       lua_ls.enable = true;
  #   #       rust_analyzer = {
  #   #         enable = true;
  #   #         installCargo = true;
  #   #         installRustc = true;
  #   #       };
  #   #     };
  #   #   };
  #   #
  #   #   treesitter.enable = true;
  #   #   which-key.enable = true;
  #   #   lualine.enable = true;
  #   #   yanky.enable = true;
  #   #   harpoon.enable = true;
  #   #   telescope.enable = true;
  #   #   mini.enable = true;
  #   #   web-devicons.enable = true;
  #   # };
  # };

  ## User level packages
  home.packages = with pkgs; [
    inputs.nixCatsNvim.packages.${pkgs.system}.nvim
    inputs.nixCatsNvim.packages.${pkgs.system}.testnvim
    vimPlugins.supermaven-nvim
    # vimPlugins.mason-tool-installer-nvim
    # vimPlugins.mason-nvim-dap-nvim
    # vimPlugins.mason-nvim
    # vimPlugins.mason-null-ls-nvim
    # vimPlugins.mason-lspconfig-nvim
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
