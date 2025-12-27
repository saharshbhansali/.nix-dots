{ pkgs, nixpkgs, lib, config, ... }:

{

  # nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [

    ## Nix utils and compatibility layers
    cachix
    # nix-ld
    steam-run
    appimage-run
    nix-inspect
    nix-index
    nh
    nix-output-monitor
    darling-dmg

    ## Hypr utils
    hyprlock
    hypridle
    hyprcursor
    numlockx

    ## Terminal essentials
    fish
    zsh
    git
    jujutsu
    # tmux
    zellij
    # neovim
    # vimPlugins.nvim-treesitter.withPlugins

    ## Terminal software
    ghostty
    kitty
    yazi
    gh # GitHub CLI
    ncdu

    ## Process utils
    pm2

    ## Networking utils
    wget
    curl
    dig
    dog

    ## Info utils
    # most
    less
    more
    man
    # tldr
    # tlrc
    tealdeer
    tree
    pciutils
    usbutils
    lshw
    procs
    dust
    strace

    ## Zip utils
    gzip
    zip
    unzip
    unrar-free
    unar
    peazip
    _7zz
    _7zz-rar

    ## Wi-Fi utils
    iw

    ## Socket utils
    netcat
    # netcat-gnu
    socat
    snicat
    dbd
    websocat

    ## Terminal enhancers
    rip2
    eza
    bat
    fzf
    fzf-preview
    ripgrep
    ripgrep-all
    fd
    jq
    sd
    btop

    ## Terminal customization
    zoxide
    pay-respects
    starship
    atuin
    carapace
    bottom
    diff-so-fancy

    ## Fetch utils
    pfetch
    fastfetch
    neofetch

    ## Keyboard and Clipboard utils
    wl-clipboard
    xclip
    xorg.xcbutil
    xorg.xmodmap
    xorg.setxkbmap
    xorg.xev

    ## Input utils
    libinput
    libinput-gestures
    wmctrl
    xdotool
    xorg.xinput
    gamepad-tool
    # xpad
    SDL2
    opengamepadui
    antimicrox
    moltengamepad
    qjoypad

    # Backlight utils
    acpilight
    xbacklight

    ## Disk utils
    parted
    gparted
    efibootmgr

    ## Backup utils
    vorta
    borgbackup
    pika-backup

    ## Media utils
    ffmpeg
    pamixer
    mpv
    vlc
    playerctl

    ## Development utils
    devenv                          # development environment manager
    devbox                          # development environment manager
    direnv                          # environment variable manager
    bintools                        # tools for manipulating binaries
    gcc                             # gcc compiler
    gdb                             # gdb debugger
    clang                           # clang compiler
    gnumake                         # make build tool
    cmake                           # cmake build system
    python-launcher                 # python version manager
    pipx                            # install python packages globally
    python313                       # python 3.13 interpreter
    python313Packages.pip           # python 3.13 package manager
    python313Packages.virtualenv    # python 3.13 virtual environment
    python312                       # python 3.12 interpreter
    python312Packages.pip           # python 3.12 package manager
    python312Packages.virtualenv    # python 3.12 virtual environment
    asdf-vm                         # asdf version manager
    mise                            # mise version manager
    volta                           # node version manager
    go                              # go programming language
    rustc                           # rust compiler
    rustup                          # rust toolchain installer
    cargo                           # rust package manager
    texliveFull                     # latex support
    lua                             # lua programming language
    # luajit                        # lua programming language
    # luajitPackages.luarocks
    # luajitPackages.luarocks-nix
    lua51Packages.lua
    lua51Packages.luarocks
    lua51Packages.luarocks-nix

    ## Android utils
    android-tools

    ## Security utils
    minisign

    ## KDE Wallet utils
    # kwalletcli
    # kdepackages.kwallet
    kdePackages.kwalletmanager

    ## GTK utils
    gtk2
    gtk3
    gtk4

    # Notification utils
    libnotify

    ## Security
    bitwarden-cli
    bitwarden-desktop
    bitwarden-menu
    ente-auth
    tor-browser

    ## Office software
    onlyoffice-desktopeditors

    ## File Management software
    kdePackages.filelight
    xfce.thunar
    xfce.thunar-archive-plugin

    ## VM Software
    vmware-workstation
    qemu

    ## Cursors and icons
    catppuccin-cursors.mochaRed
    catppuccin-cursors.mochaMauve
    catppuccin-cursors.mochaLavender
    rose-pine-cursor
    # rose-pine-hyprcursor

    ## Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    nerd-fonts.dejavu-sans-mono

    ## Unicode and globalization support
    icu

  ];

}
