{ pkgs, nixpkgs, lib, config, ... }:

{

  # nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [

    # Nix utils
    nix-inspect
    steam-run
    appimage-run
    nix-index

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
    # tldr
    # tlrc
    tealdeer
    tree
    pciutils
    procs
    dust

    # Terminal enhancers
    rip2
    eza
    bat
    fzf
    fd
    jq
    sd

    # Terminal customization
    zoxide
    pay-respects
    starship
    atuin
    carapace
    btop
    bottom
    diff-so-fancy

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
    gcc                             # gcc compiler
    clang                           # clang compiler
    gnumake                         # make build tool
    cmake                           # cmake build system
    python313                       # python 3.13 interpreter
    python313Packages.pip           # python 3.13 package manager
    python313Packages.virtualenv    # python 3.13 virtual environment
    python312                       # python 3.12 interpreter
    python312Packages.pip           # python 3.12 package manager
    python312Packages.virtualenv    # python 3.12 virtual environment
    python-launcher                 # python version manager
    pipx                            # install python packages globally
    strace                          # for tracing system calls
    gdb                             # for debugging

    # KDE Wallet utils
    # kwalletcli
    # kdepackages.kwallet
    kdePackages.kwalletmanager

    # GTK utils
    gtk2
    gtk3
    gtk4

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

    # SDDM themeing
    where-is-my-sddm-theme

    # Cursors and icons
    catppuccin-cursors.mochaRed
    catppuccin-cursors.mochaMauve
    catppuccin-cursors.mochaLavender
    rose-pine-cursor
    # rose-pine-hyprcursor

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    nerd-fonts.dejavu-sans-mono

  ];

}
