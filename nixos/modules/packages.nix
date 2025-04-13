{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
  ];

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
