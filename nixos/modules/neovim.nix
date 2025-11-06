{ config, pkgs, lib, inputs, ... }:

{
  # imports = [ inputs.nixCatsNvim.nixosModules.default ];

  environment.systemPackages = [
    inputs.nixCatsNvim.packages.${pkgs.system}.nvim
  ];

  # Mount custom config directory
  environment.etc."lazynvim".source = ../../configs/nvim;

  # Create a symlink to ~/.config/nvim → /etc/lazyvim
  systemd.user.tmpfiles.rules = [
    "L+ /root/.config/nvim - - - - /etc/lazyvim"
    "L+ /etc/nvim - - - - /etc/lazyvim"
  ];

}
