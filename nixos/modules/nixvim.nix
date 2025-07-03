{ config, lib, pkgs, inputs, ... }:

{
  # assuming nvf is in your inputs and inputs is in the argset
  # see example below
  imports = [ inputs.nvf.nixosModules.default ];

  programs.nvf = {
    enable = true;
    # your settings need to go into the settings attribute set
    # most settings are documented in the appendix
    settings = {
      vim.viAlias = false;
      vim.vimAlias = true;
      vim.lsp = {
        enable = true;
      };
    };
  };
}
