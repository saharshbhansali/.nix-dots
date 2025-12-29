# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modular NixOS + Home Manager configuration using flakes. The configuration is split into two layers:
- **NixOS modules** (`nixos/modules/`): System-wide configuration
- **Home Manager modules** (`home-manager/modules/`): User-specific configuration

The hostname defined in the flake is `nixos` - this is used when applying configurations.

## Common Commands

```bash
# Rebuild and switch to new configuration (most common)
sudo nixos-rebuild switch --flake .

# Update flake inputs
nix flake update

# Build without switching (useful for testing)
nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Check configuration for errors without building
nix flake check
```

## Architecture

### Module Organization

**System modules** are imported in `nixos/hosts/default.nix`:
- System: `boot.nix`, `filesystem.nix`, `networking.nix`, `graphics.nix`, `power-management.nix`
- Packages: `packages.nix`, `programs.nix`, `flatpaks.nix`, `appimages.nix`
- Features: `gaming.nix`, `shell.nix`
- Configs: `neovim.nix`, `tmux.nix`, `services.nix`, `gestures.nix`
- Desktop: `gnome-desktop.nix`, `kde-desktop.nix`, `cosmic-desktop.nix` (only one enabled at a time)

**User modules** are imported in `home-manager/users/default.nix`:
- All prefixed with `hm-`: `hm-packages.nix`, `hm-programs.nix`, `hm-devtools.nix`, etc.

### Application Configs

Application-specific dotfiles live in `configs/` and are symlinked via `home-manager/modules/hm-configs.nix`. When adding a new application config:
1. Place files in `configs/<appname>/`
2. Add symlink in `hm-configs.nix` using `home.file.".config/<appname>"`

### Neovim Configuration

The repository contains multiple Neovim setups:
- `nixos/modules/nixCats-nvim/`: nixCats-nvim flake (currently commented out)
- `nixos/modules/nixPatch-nvim/`: nixPatch-nvim flake (currently commented out)
- `configs/nvim/`: LazyVim configuration (traditional Lua files)

The system currently uses the Lua-based LazyVim config from `configs/nvim/`.

### Desktop Environments

Multiple desktop environments are configured but only one should be enabled at a time:
- GNOME: Enable `gnome-desktop.nix` and `gdm.nix`, disable KDE modules
- KDE: Enable `kde-desktop.nix` and `sddm.nix`, disable GNOME modules (current)
- Cosmic: Enable `cosmic-desktop.nix`, disable others

### Flake Inputs

External dependencies are managed in `flake.nix`:
- `nixpkgs`: nixos-unstable channel
- `home-manager`: User configuration management
- `nur`: Nix User Repository
- `nixvim`: Neovim configuration (Nix-based)
- `zen-browser`: Zen browser flake
- `spicetify-nix`: Spotify customization

To add a new flake input, update `inputs` in `flake.nix` and pass it via `specialArgs`.

## Filesystem Notes

- Uses BTRFS with zstd compression
- Separate subvolumes: `/`, `/nix`, `/home`, `/swap`
- `/nix` mounted with `noatime` for performance
- Docker uses BTRFS storage driver with rootless mode enabled

## Development Tools

The system includes:
- Shells: zsh (default), fish, nushell
- AI tools: Claude Code, OpenCode
- Node.js: npm, yarn, pnpm
- Version control: git, jj (jujutsu)

## User Configuration

- User: `saharsh`
- Groups: `wheel`, `video`, `audio`, `input`
- Shell: zsh (with Powerlevel10k)
