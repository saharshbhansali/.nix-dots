{ config, pkgs, lib, inputs, ... }:

{
  # imports = [ inputs.nixvim.nixosModules.nixvim ];
  #
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
  #   plugins = {
  #     lazy.enable = true;
  #
  #     lsp = {
  #       enable = true;
  #       servers = {
  #         lua_ls.enable = true;
  #         rust_analyzer = {
  #           enable = true;
  #           installCargo = true;
  #           installRustc = true;
  #         };
  #       };
  #     };
  #
  #     treesitter.enable = true;
  #     which-key.enable = true;
  #     lualine.enable = true;
  #     yanky.enable = true;
  #     harpoon.enable = true;
  #     telescope.enable = true;
  #     mini.enable = true;
  #     web-devicons.enable = true;
  #   };
  # };


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

  # Mount custom config directory
  environment.etc."lazynvim".source = ../../configs/nvim;

  # Create a symlink to ~/.config/nvim → /etc/lazyvim
  systemd.user.tmpfiles.rules = [
      "L+ /root/.config/nvim - - - - /etc/lazyvim"
      "L+ /etc/nvim - - - - /etc/lazyvim"
  ];

}
