{ pkgs, nixpkgs, lib, config, inputs, ... }:

{

  # nixpkgs.config.allowUnfree = true;

  # Nix Index database (pre-populated nix-index)
  imports = [
    inputs.nix-index-database.nixosModules.default
  ];
  programs.nix-index-database.comma.enable = true;

  environment.systemPackages = with pkgs; [

    ## Nix utils and compatibility layers
    util-linux
    cachix
    # nix-ld
    steam-run
    appimage-run
    nix-inspect
    # nix-index ## using nix-index-database (pre-populated nix-index) instead
    nh
    nix-output-monitor
    darling-dmg
    winboat

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
    net-tools
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

    ## Container utils and tools
    lazydocker
    minikube
    kubernetes
    # kubernetes-helm
    kubernetes-helm-wrapped
    kubectl
    kubernix

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
    # neofetch

    ## Keyboard and Clipboard utils
    wl-clipboard
    xclip
    xcbutil
    xmodmap
    setxkbmap
    xev

    ## Input utils
    libinput
    libinput-gestures
    wmctrl
    xdotool
    xinput
    gamepad-tool
    # xpad
    SDL2
    # opengamepadui
    antimicrox
    moltengamepad
    qjoypad

    # Backlight utils
    acpilight
    xbacklight

    ## Disk utils
    e2fsprogs
    kdePackages.partitionmanager
    parted
    gparted
    efibootmgr

    ## USB utils
    usb-modeswitch
    usb-modeswitch-data

    ## Backup utils
    vorta
    borgbackup
    pika-backup

    ## Media utils
    ffmpeg
    pamixer
    pavucontrol
    mpv
    vlc
    playerctl
    # uxplay
    # owntone
    gnome-network-displays
    mkchromecast
    # gnomecast

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
    python314                       # python 3.14 interpreter
    python314Packages.uv            # python 3.14 package manager
    python314Packages.pip           # python 3.14 package manager
    python314Packages.virtualenv    # python 3.14 virtual environment
    python313                       # python 3.13 interpreter
    python313Packages.uv            # python 3.14 package manager
    python313Packages.pip           # python 3.13 package manager
    python313Packages.virtualenv    # python 3.13 virtual environment
    asdf-vm                         # asdf version manager
    mise                            # mise version manager
    volta                           # node version manager
    bun                             # fast javascript bundler
    yarn                            # fast javascript dependency manager
    pnpm                            # fast and disk-space efficient javascript package manager
    go                              # go programming language
    rustc                           # rust compiler
    rustup                          # rust toolchain installer
    cargo                           # rust package manager
    texliveFull                     # latex support
    lua                             # lua programming language
    # luajit                        # lua programming language
    # luajitPackages.luarocks
    # luajitPackages.luarocks-nix
    lua51Packages.lua               # lua programming language
    lua51Packages.luarocks          # lua package manager
    lua51Packages.luarocks-nix      # lua package manager for nix
    lua51Packages.tree-sitter-cli   # lua tree-sitter cli
    ghostscript                     # postscript interpreter
    ## Extra dev tools
    mermaid-cli                     # generate diagrams

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

    # Email software
    thunderbird

    ## File Management software
    kdePackages.filelight
    thunar
    thunar-archive-plugin

    ## VM Software
    vmware-workstation
    qemu

    ## RDP Software
    freerdp
    xrdp
    # rdpgw

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
