{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    tmux
  ];

  # Mount custom config directory
  environment.etc."tmux".source = ../../configs/tmux;
  environment.etc."oh-my-tmux".source = ../../configs/oh-my-tmux;
  environment.etc."tmux-which-key".source = ../../configs/tmux-which-key;

  # Create a symlink to ~/.config/tmux → /etc/tmux
  systemd.user.tmpfiles.rules = [
    "L+ /root/.config/tmux - - - - /etc/tmux"
    "L+ /root/.config/oh-my-tmux - - - - /etc/oh-my-tmux"
    "L+ /root/.config/tmux-which-key - - - - /etc/tmux-which-key"
  ];
}
