# Plan: Modularize NixOS + Home Manager Configuration

## Overview

Convert the configuration from simple functions to proper Nix modules with enable options, following the pattern from [vimjoyer/modularize-video](https://github.com/vimjoyer/modularize-video).

## Phase 1: Module Pattern Refactoring

### Goal
Convert all modules from simple functions to proper modules with `options` and `config` sections, using `lib.mkIf` for conditional configuration.

### Pattern Template

```nix
# modules/something.nix
{ config, lib, pkgs, inputs, ... }:

{
  options = {
    something.enable = lib.mkEnableOption "enables something";
    something.extraOptions = lib.mkOption {
      type = lib.types.str;
      default = "default value";
      description = "description of option";
    };
  };

  config = lib.mkIf config.something.enable {
    # configuration goes here
  };
}
```

### NixOS Modules to Convert (nixos/modules/)

| File | Module Name | Description |
|------|-------------|-------------|
| `packages.nix` | `systemPackages.enable` | System-wide packages |
| `programs.nix` | `systemPrograms.enable` | System programs |
| `flatpaks.nix` | `flatpaks.enable` | Flatpak support |
| `appimages.nix` | `appimages.enable` | AppImage support |
| `shell.nix` | `systemShell.enable` | Shell configuration |
| `gaming.nix` | `gaming.enable` | Gaming/Steam setup |
| `neovim.nix` | `neovim-system.enable` | Neovim system config |
| `tmux.nix` | `tmux-system.enable` | Tmux system config |
| `services.nix` | `systemServices.enable` | System services |
| `gestures.nix` | `libinputGestures.enable` | Touch gestures |
| `gnome-desktop.nix` | `gnome-desktop.enable` | GNOME desktop |
| `kde-desktop.nix` | `kde-desktop.enable` | KDE desktop |
| `cosmic-desktop.nix` | `cosmic-desktop.enable` | Cosmic desktop |

### Home Manager Modules to Convert (home-manager/modules/)

| File | Module Name | Description |
|------|-------------|-------------|
| `hm-packages.nix` | `myPackages.enable` | User packages |
| `hm-programs.nix` | `myPrograms.enable` | User programs |
| `hm-flatpaks.nix` | `myFlatpaks.enable` | User flatpaks |
| `hm-devtools.nix` | `devTools.enable` | Development tools |
| `hm-nvim.nix` | `neovim-user.enable` | Neovim user config |
| `hm-nushell.nix` | `nushell.enable` | Nushell shell |
| `hm-spicetify.nix` | `spicetify.enable` | Spotify customization |
| `hm-gaming.nix` | `gaming-user.enable` | User gaming apps |
| `hm-networking.nix` | `userNetworking.enable` | User networking |
| `hm-configs.nix` | `dotfiles.enable` | Dotfile symlinks |
| `hm-shell.nix` | `userShell.enable` | User shell config |

### Flake Structure Changes

```nix
# flake.nix - new structure
{
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # NixOS module output for importing
    nixosModules = {
      # Individual modules
      systemPackages = ./nixos/modules/packages.nix;
      gaming = ./nixos/modules/gaming.nix;
      # ... all other modules

      # All modules as a set
      default = {
        imports = with self.nixosModules; [
          systemPackages
          gaming
          # ...
        ];
      };
    };

    # Home Manager module output
    homeManagerModules = {
      # Individual modules
      myPackages = ./home-manager/modules/hm-packages.nix;
      neovim-user = ./home-manager/modules/hm-nvim.nix;
      # ...

      default = {
        imports = with self.homeManagerModules; [
          myPackages
          neovim-user
          # ...
        ];
      };
    };

    # NixOS configurations
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        ./hardware-configuration.nix
        ./nixos/hosts/default.nix
        self.nixosModules.default
        # Home Manager integration
        home-manager.nixosModules.home-manager
        {
          home-manager.users.saharsh = {
            imports = [ self.homeManagerModules.default ];
          };
        }
      ];
    };
  };
}
```

## Phase 2: Multi-Target Configuration Structure

### Goal
Enable the configuration to work in multiple scenarios:
1. **NixOS + Home Manager** (full setup on NixOS)
2. **Home Manager standalone** (on non-NixOS distros like Ubuntu/Arch)
3. **NixOS standalone** (without Home Manager)

### New File Organization

```
.
├── configs/                          # ~/.config type files (app-level configs)
│   ├── nvim/                         # Neovim/LazyVim config
│   ├── tmux/                         # Tmux configuration
│   ├── kitty/                        # Kitty terminal configs
│   ├── fish/                         # Fish shell config
│   ├── zsh/                          # Zsh + Powerlevel10k
│   ├── oh-my-tmux/                   # Git submodule
│   └── ...                           # Other app configs
│
├── home-manager/
│   ├── modules/                      # Home Manager modules (with options)
│   │   ├── hm-packages.nix
│   │   ├── hm-nvim.nix
│   │   ├── hm-configs.nix           # Links configs/ to home directory
│   │   └── ...
│   └── users/
│       ├── default.nix               # Shared user config base
│       ├── saharsh/
│       │   └── config.nix            # Used with nixos/hosts/default (NixOS setup)
│       ├── generic/
│       │   └── config.nix            # Used with nixos/hosts/generic (non-NixOS user)
│       └── standalone/
│           └── config.nix            # Pure Home Manager flake (works on any distro)
│                                      # Use: home-manager switch --flake .#standalone
│
├── nixos/
│   ├── modules/                      # NixOS modules (with options)
│   │   ├── packages.nix
│   │   ├── gaming.nix
│   │   └── ...
│   └── hosts/
│       ├── default/
│       │   ├── hardware.nix          # Hardware configuration
│       │   └── config.nix            # Host config (uses HM user saharsh)
│       ├── generic/
│       │   ├── hardware.nix          # Generic hardware template
│       │   └── config.nix            # Host config (uses HM user generic)
│       └── standalone/
│           ├── hardware.nix          # Hardware configuration
│           └── config.nix            # NixOS-only (no Home Manager)
│                                      # Uses configs/ via environment.etc or symlinks
│
├── flake.nix                         # Main flake (NixOS + HM)
└── flake.home.nix                    # Standalone Home Manager flake
```

### Configs Directory Role

The `configs/` directory contains all application-level configuration files that would normally live in `~/.config/`. These are consumed in two ways:

1. **Via Home Manager** (`hm-configs.nix`):
   ```nix
   home.file.".config/nvim" = {
     source = ../../configs/nvim;
     recursive = true;
   };
   ```

2. **Via NixOS standalone** (no Home Manager):
   ```nix
   # Mount to /etc for system-wide reference
   environment.etc."nvim".source = ./configs/nvim;

   # Or create symlinks via tmpfiles
   systemd.tmpfiles.rules = [
     "L+ /root/.config/nvim - - - - /etc/nvim"
   ];
   ```

### User Configurations

#### home-manager/users/default.nix (Shared Base)

```nix
# Shared base configuration for all users
{ config, lib, pkgs, inputs, ... }:

{
  home.stateVersion = "24.11";

  # Import shared modules
  imports = [
    ../../home-manager/modules/hm-packages.nix
    ../../home-manager/modules/hm-programs.nix
    ../../home-manager/modules/hm-configs.nix
    # ... other common modules
  ];

  # Common settings
  home.username = lib.mkDefault config.home.username;
  home.homeDirectory = lib.mkDefault config.home.homeDirectory;
}
```

#### home-manager/users/saharsh/config.nix (NixOS User)

```nix
# User for NixOS systems with full hardware access
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ./default.nix ];

  home.username = "saharsh";
  home.homeDirectory = "/home/saharsh";

  # NixOS-specific user settings
  myPackages.enableNixOSPackages = true;
  neovim.flavor = "nixcats";  # Can use nixCats with system packages
}
```

#### home-manager/users/generic/config.nix (Non-NixOS User)

```nix
# User for non-NixOS systems (Ubuntu, Arch, etc.)
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ./default.nix ];

  home.username = lib.mkDefault "saharsh";  # Can be overridden
  home.homeDirectory = lib.mkDefault "/home/saharsh";

  # Non-NixOS specific settings
  myPackages.enableNixOSPackages = false;  # Skip packages only available on NixOS
  neovim.flavor = "lazyvim";  # Use standard LazyVim without nixCats
}
```

#### home-manager/users/standalone/config.nix (Pure HM Flake)

```nix
# Independent Home Manager configuration
# Use: home-manager switch --flake .#standalone
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ./default.nix ];

  home.username = lib.mkDefault "saharsh";
  home.homeDirectory = lib.mkDefault "/home/saharsh";

  # Everything within Home Manager scope
  myPackages.enable = true;
  myPrograms.enable = true;
  dotfiles.enable = true;
  neovim.enable = true;

  # No NixOS-specific features
  systemd.user.startServices = true;
}
```

### Host Configurations

#### nixos/hosts/default/config.nix (with HM user saharsh)

```nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../../nixos/modules  # Or import specific modules
  ];

  # Enable desired modules
  systemPackages.enable = true;
  gaming.enable = true;
  kde-desktop.enable = true;

  # Home Manager integration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.saharsh = import ../../../home-manager/users/saharsh/config.nix;
    extraSpecialArgs = { inherit inputs; };
  };
}
```

#### nixos/hosts/generic/config.nix (with HM user generic)

```nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../../nixos/modules
  ];

  # More conservative defaults for generic hardware
  systemPackages.enable = true;
  gaming.enable = lib.mkDefault false;

  # Home Manager integration with generic user
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      saharsh = import ../../../home-manager/users/generic/config.nix;
    };
    extraSpecialArgs = { inherit inputs; };
  };
}
```

#### nixos/hosts/standalone/config.nix (NixOS-only, no HM)

```nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../../nixos/modules
  ];

  # All NixOS features
  systemPackages.enable = true;
  gaming.enable = true;

  # Config files via NixOS (no Home Manager)
  environment.etc."nvim".source = ../../../configs/nvim;
  environment.etc."kitty".source = ../../../configs/kitty;

  # Create symlinks for root/user access
  systemd.tmpfiles.rules = [
    "L+ /root/.config/nvim - - - - /etc/nvim"
    "L+ /root/.config/kitty - - - - /etc/kitty"
  ];

  # Users get configs via /etc reference or manual symlinks
  users.users.saharsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];
  };
}
```

### Flake Outputs

```nix
# flake.nix
{
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # NixOS configurations
    nixosConfigurations = {
      # Full NixOS + Home Manager (default setup)
      default = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/hosts/default/config.nix
        ];
      };

      # Generic host with generic HM user
      generic = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/hosts/generic/config.nix
        ];
      };

      # NixOS standalone (no Home Manager)
      standalone = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/hosts/standalone/config.nix
        ];
      };
    };
  };
}
```

```nix
# flake.home.nix - Standalone Home Manager flake
{
  description = "Standalone Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Copy other inputs from main flake
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    homeConfigurations = {
      # Standalone Home Manager (works on any Linux distro)
      standalone = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager/users/standalone/config.nix
        ];
        extraSpecialArgs = { inherit inputs; };
      };

      # Generic user for other distros
      generic = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager/users/generic/config.nix
        ];
        extraSpecialArgs = { inherit inputs; };
      };
    };
  };
}
```

### Usage Commands

```bash
# NixOS + Home Manager (default)
sudo nixos-rebuild switch --flake .#default

# NixOS + Home Manager (generic)
sudo nixos-rebuild switch --flake .#generic

# NixOS standalone (no Home Manager)
sudo nixos-rebuild switch --flake .#standalone

# Standalone Home Manager (on any distro)
home-manager switch --flake flake.home.nix#standalone

# Generic Home Manager on other distro
home-manager switch --flake flake.home.nix#generic
```

## Phase 3: WiFi/Networking Fix

### Current Issue
Realtek WiFi card (wlo1) has connection issues. Currently disabled via systemd user service.

### Solutions to Implement

1. **Update kernel and firmware**
   ```nix
   boot.kernelPackages = pkgs.linuxPackages_latest;
   hardware.enableRedistributableFirmware = true;
   ```

2. **Proper module for Realtek WiFi**
   ```nix
   # nixos/modules/realtek-wifi.nix
   { config, lib, pkgs, ... }:
   {
     options = {
       realtek-wifi.enable = lib.mkEnableOption "Realtek WiFi support";
     };

     config = lib.mkIf config.realtek-wifi.enable {
       boot.kernelModules = [ "rtw89" ];
       hardware.wirelessRegulatoryDomain = true;
       networking.wireless.iwd.enable = true;
     };
   }
   ```

3. **NetworkManager configuration** - more robust setup:
   ```nix
   networking.networkmanager = {
     enable = true;
     wifi.powersave = false;  # Disable power saving for stability
   };
   ```

## Phase 4: Declarative Partitioning with Disko

### Goal
Use [disko](https://github.com/nix-community/disko) for declarative disk management.

### Implementation

1. **Add disko input**:
   ```nix
   disko = {
     url = "github:nix-community/disko";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. **Create disk configuration**:
   ```nix
   # nixos/hosts/default/disk-config.nix
   { disks ? [ "/dev/nvme0n1" ], ... }:
   {
     disko.devices = {
       disk = {
         main = {
           type = "disk";
           device = builtins.head disks;
           content = {
             type = "gpt";
             partitions = {
               boot = {
                 size = "1G";
                 type = "EF00";
                 content = {
                   type = "filesystem";
                   format = "vfat";
                   mountpoint = "/boot";
                 };
               };
               root = {
                 size = "100%";
                 content = {
                   type = "btrfs";
                   extraArgs = [ "-f" ];
                   subvolumes = {
                     "/root" = { mountpoint = "/"; };
                     "/home" = { mountpoint = "/home"; };
                     "/nix" = {
                       mountpoint = "/nix";
                       mountOptions = [ "noatime" "compress=zstd" ];
                     };
                     "/swap" = { mountpoint = "/swap"; };
                   };
                 };
               };
             };
           };
         };
       };
     };
   }
   ```

3. **Update host configurations** to use disko module instead of manual filesystem config.

## Phase 5: Neovim Module Refactoring

### Goal
Create working, standalone nixCats and nixPatch nvim modules that can be used on any system.

### Current State
- `nixCats-nvim/`: Git submodule, working but needs module wrapper
- `nixPatch-nvim/`: Git submodule, broken (commented out)
- `configs/nvim/`: LazyVim config (Lua files)

### Implementation Plan

#### 1. Fix nixPatch-nvim submodule

Ensure the git submodule is properly initialized:
```bash
cd nixos/modules/nixPatch-nvim
git submodule update --init --recursive
```

#### 2. Create unified Neovim module

```nix
# nixos/modules/neovim-wrapper.nix
{ config, lib, pkgs, inputs, ... }:

{
  options = {
    neovim = {
      enable = lib.mkEnableOption "Neovim";
      flavor = lib.mkOption {
        type = lib.types.enum [ "nixcats" "nixpatch" "lazyvim" ];
        default = "lazyvim";
        description = "Which Neovim configuration to use";
      };
    };
  };

  config = lib.mkIf config.neovim.enable {
    environment.systemPackages = lib.optional (config.neovim.flavor == "lazyvim")
      pkgs.neovim;

    imports = lib.optional (config.neovim.flavor == "nixcats") ./nixcats-nvim.nix
      ++ lib.optional (config.neovim.flavor == "nixpatch") ./nixpatch-nvim.nix;
  };
}
```

#### 3. Home Manager Neovim module

```nix
# home-manager/modules/neovim-standalone.nix
{ config, lib, pkgs, inputs, ... }:

let
  inherit (pkgs.stdenv) hostPlatform;
in
{
  options = {
    neovim = {
      enable = lib.mkEnableOption "Neovim";
      flavor = lib.mkOption {
        type = lib.types.enum [ "nixcats" "nixpatch" "lazyvim" ];
        default = "lazyvim";
      };
    };
  };

  config = lib.mkIf config.neovim.enable {
    home.packages = with pkgs; [ neovim ];

    imports = lib.optional (config.neovim.flavor == "nixcats")
      inputs.nixCatsNvim.homeModules.default
      ++ lib.optional (config.neovim.flavor == "nixpatch")
      inputs.nixPatchNvim.homeModules.default;
  };
}
```

## Phase 6: Cross-Machine Portability

### Goal
Make the configuration portable across different computers with different hardware.

### Strategy

1. **Host-specific hardware configs** - Each host has its own `hardware.nix`
2. **Generic user config** - `home-manager/users/generic/` works on any distro
3. **Feature flags** - Enable/disable modules based on host capabilities
4. **Profile-based configuration** - Desktop vs laptop profiles

### Example Profile System

```nix
# home-manager/profiles/desktop.nix
{ config, lib, pkgs, ... }:

{
  myPackages.enableDesktopPackages = true;
  myPackages.enableLaptopPackages = false;
  kde-desktop.enable = true;
  gaming.enable = true;
}

# home-manager/profiles/laptop.nix
{ config, lib, pkgs, ... }:

{
  myPackages.enableDesktopPackages = false;
  myPackages.enableLaptopPackages = true;
  power-management.enable = true;
  gaming.enable = false;  # Save battery
}
```

## Implementation Order

1. **Phase 1** - Core module pattern (highest priority)
   - Start with simple modules (gaming, flatpaks)
   - Work up to complex ones (packages, desktop)
   - Update flake.nix to export modules

2. **Phase 2** - Multi-target structure
   - Reorganize home-manager/users/
   - Reorganize nixos/hosts/
   - Create standalone Home Manager flake
   - Test on non-NixOS system

3. **Phase 5** - Neovim modules (can be done in parallel)
   - Fix nixPatch-nvim submodule
   - Create unified Neovim wrapper
   - Test standalone Neovim module

4. **Phase 3** - WiFi fix
   - Implement Realtek module
   - Test and refine

5. **Phase 4** - Disko integration
   - Create disk config
   - Test on non-critical system first

6. **Phase 6** - Cross-machine portability
   - Implement profile system
   - Document host setup process

## Testing Strategy

After each phase:
```bash
# Check syntax
nix flake check

# Dry run build
nixos-rebuild build --flake .#default

# Test switch (NixOS)
sudo nixos-rebuild switch --flake .#default

# Test standalone Home Manager
home-manager switch --flake flake.home.nix#standalone

# Test generic user on non-NixOS
home-manager switch --flake flake.home.nix#generic
```

## Migration Notes

- Keep old modules during transition
- Use `lib.mkIf` so disabled modules add nothing to config
- Document each module's options in CLAUDE.md
- Update CLAUDE.md with new build commands and structure
- Maintain backwards compatibility where possible
