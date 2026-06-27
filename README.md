# Dotfiles

Configuration for the tools I use day to day.

Each folder contains configuration for a specific tool. `install.sh` installs the minimal Homebrew bundle, recreates generated plugin dependencies, backs up any existing target files, and symlinks the tracked config into place.

## Install

```sh
./install.sh
```

Useful flags:

```sh
./install.sh --dry-run
./install.sh --no-brew
./install.sh --no-services
```

Backups are written to `~/.dotfiles-backup/<timestamp>`.
