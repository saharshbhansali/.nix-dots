{ pkgs, nixpkgs, ... }:

{
  # nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [

    # Nix utils
    nix-inspect
    steam-run
    appimage-run

    # Hypr utils
    hyprlock
    hypridle
    hyprcursor
    numlockx

    # Terminal essentials
    fish
    zsh
    git
    tmux
    # neovim
    # vimPlugins.nvim-treesitter.withPlugins

    # Terminal software
    kitty
    yazi

    ## Terminal utils

    # Networking utils
    wget
    curl

    # Info utils
    # most
    less
    more
    man
    tree
    pciutils

    # Terminal enhancers
    zoxide
    rip2
    eza
    bat
    fzf
    fd
    tldr
    diff-so-fancy
    thefuck
    btop

    # Fetch utils
    pfetch
    fastfetch
    neofetch

    # Keyboard and Clipboard utils
    wl-clipboard
    xclip
    xorg.xcbutil
    xorg.xmodmap
    xorg.setxkbmap
    xorg.xev

    # Gesture utils
    libinput
    libinput-gestures
    wmctrl
    xdotool

    # Disk utils
    parted
    gparted
    efibootmgr

    # Backup utils
    vorta
    borgbackup
    pika-backup

    # Media utils
    pamixer

    # Development utils
    devenv
    direnv
    gcc                    # gcc compiler
    clang                  # clang compiler
    gnumake                # make build tool
    cmake                  # cmake build system
    python313              # python 3 interpreter
    python313Packages.pip  # python 3 package manager
    pipx                   # install python packages globally
    strace                 # for tracing system calls
    gdb                    # for debugging

    # KDE Wallet utils
    # kwalletcli
    # kdepackages.kwallet
    kdePackages.kwalletmanager

    # GTK utils
    gtk2
    gtk3
    gtk4

    # SDDM themeing
    where-is-my-sddm-theme

    # Cursors and icons
    catppuccin-cursors.mochaRed
    catppuccin-cursors.mochaMauve
    catppuccin-cursors.mochaLavender
    rose-pine-cursor
    # rose-pine-hyprcursor

    # BitWarden
    bitwarden-cli
    bitwarden-desktop
    bitwarden-menu

    # Office software
    onlyoffice-bin

    # File Management software
    kdePackages.filelight
    xfce.thunar
    xfce.thunar-archive-plugin

    # # VM Software
    # vmware-workstation

  ];

  programs.zsh.enable = true;

  ## Enable programs

  # dconf editor for GNOME settings
  programs.dconf.enable = true;

  # # enable hyprlock
  # programs.hyprlock.enable = true;

}
