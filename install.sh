#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)}"

DRY_RUN=0
INSTALL_BREW=1
START_SERVICES=1

usage() {
  printf '%s\n' "usage: $0 [--dry-run] [--no-brew] [--no-services]"
}

log() {
  printf '%s\n' "$*"
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --no-brew)
      INSTALL_BREW=0
      ;;
    --no-services)
      START_SERVICES=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  log "Installing Homebrew"
  if [ "$DRY_RUN" -eq 1 ]; then
    log '+ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

setup_brew_env() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_packages() {
  [ "$INSTALL_BREW" -eq 1 ] || return 0

  ensure_homebrew
  setup_brew_env

  # Required for yabai from asmvik/formulae on current Homebrew versions.
  run brew trust asmvik/formulae || true
  run brew trust felixkratz/formulae || true

  log "Installing Homebrew bundle"
  run brew bundle --file "$DOTFILES_DIR/Brewfile"
}

backup_path() {
  target="$1"

  case "$target" in
    "$HOME"/*)
      relative="${target#"$HOME"/}"
      ;;
    *)
      relative="${target#/}"
      ;;
  esac

  backup_target="$BACKUP_DIR/$relative"
  run mkdir -p "$(dirname -- "$backup_target")"
  log "Backing up $target -> $backup_target"
  run mv "$target" "$backup_target"
}

link_path() {
  source_path="$1"
  target_path="$2"

  if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
    printf 'missing source: %s\n' "$source_path" >&2
    return 1
  fi

  run mkdir -p "$(dirname -- "$target_path")"

  if [ -L "$target_path" ]; then
    current_target="$(readlink "$target_path")"
    if [ "$current_target" = "$source_path" ] || [ "$current_target" = "$source_path/" ]; then
      log "Already linked: $target_path"
      return 0
    fi

    backup_path "$target_path"
  elif [ -e "$target_path" ]; then
    backup_path "$target_path"
  fi

  log "Linking $target_path -> $source_path"
  run ln -s "$source_path" "$target_path"
}

install_tmux_tpm() {
  tpm_dir="$XDG_DATA_HOME/tmux/plugins/tpm"

  if [ -d "$tpm_dir/.git" ]; then
    return 0
  fi

  run mkdir -p "$(dirname -- "$tpm_dir")"
  log "Installing TPM -> $tpm_dir"
  run git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
}

install_zellij_plugins() {
  plugin_dir="$XDG_DATA_HOME/zellij/plugins"
  legacy_dir="$XDG_CONFIG_HOME/zellij/plugins"

  run mkdir -p "$plugin_dir"

  install_zellij_plugin \
    room.wasm \
    https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm

  install_zellij_plugin \
    zellij_forgot.wasm \
    https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm

  install_zellij_plugin \
    zjstatus.wasm \
    https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm
}

install_zellij_plugin() {
  name="$1"
  url="$2"
  destination="$XDG_DATA_HOME/zellij/plugins/$name"
  legacy_file="$XDG_CONFIG_HOME/zellij/plugins/$name"

  if [ -s "$destination" ]; then
    log "Already installed: $destination"
    return 0
  fi

  if [ -s "$legacy_file" ]; then
    log "Preserving existing Zellij plugin: $name"
    run cp "$legacy_file" "$destination"
    return 0
  fi

  temporary="$destination.tmp"
  log "Downloading Zellij plugin: $name"
  run curl -fL "$url" -o "$temporary"
  run mv "$temporary" "$destination"
}

set_permissions() {
  run chmod 755 \
    "$DOTFILES_DIR/install.sh" \
    "$DOTFILES_DIR/yabai/yabairc" \
    "$DOTFILES_DIR/yabai/wm.sh" \
    "$DOTFILES_DIR/sketchybar/sketchybarrc" \
    "$DOTFILES_DIR/sketchybar/diagnose.sh" \
    "$DOTFILES_DIR"/sketchybar/plugins/*.sh \
    "$DOTFILES_DIR"/zellij/scripts/*.sh

  run chmod 644 \
    "$DOTFILES_DIR/.gitignore" \
    "$DOTFILES_DIR/Brewfile" \
    "$DOTFILES_DIR/README.md" \
    "$DOTFILES_DIR/git/config" \
    "$DOTFILES_DIR/git/gitignore" \
    "$DOTFILES_DIR/git/ignore" \
    "$DOTFILES_DIR/starship/starship.toml" \
    "$DOTFILES_DIR/tmux/tmux.conf" \
    "$DOTFILES_DIR/zsh/.zshrc" \
    "$DOTFILES_DIR/zsh/.zsh_plugins.txt" \
    "$DOTFILES_DIR/zsh/aliases.zsh" \
    "$DOTFILES_DIR/skhd/skhdrc" \
    "$DOTFILES_DIR/sketchybar/colors.sh" \
    "$DOTFILES_DIR/sketchybar/icon_map.sh" \
    "$DOTFILES_DIR/sketchybar/settings.sh" \
    "$DOTFILES_DIR/zellij/config.kdl" \
    "$DOTFILES_DIR/zellij/layouts"/*.kdl
}

link_dotfiles() {
  run mkdir -p "$XDG_CONFIG_HOME"

  link_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_path "$DOTFILES_DIR/zsh/.zsh_plugins.txt" "$HOME/.zsh_plugins.txt"
  link_path "$DOTFILES_DIR/git" "$XDG_CONFIG_HOME/git"
  link_path "$DOTFILES_DIR/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
  link_path "$DOTFILES_DIR/tmux" "$XDG_CONFIG_HOME/tmux"
  link_path "$DOTFILES_DIR/yabai" "$XDG_CONFIG_HOME/yabai"
  link_path "$DOTFILES_DIR/skhd" "$XDG_CONFIG_HOME/skhd"
  link_path "$DOTFILES_DIR/sketchybar" "$XDG_CONFIG_HOME/sketchybar"
  link_path "$DOTFILES_DIR/zellij" "$XDG_CONFIG_HOME/zellij"
}

start_services() {
  [ "$START_SERVICES" -eq 1 ] || return 0

  setup_brew_env
  command -v brew >/dev/null 2>&1 || return 0

  log "Starting Homebrew services when available"
  run brew services start sketchybar || true
  run brew services start yabai || true
  run brew services start skhd || true
  run brew services start skhd-zig || true
}

main() {
  install_packages
  set_permissions
  install_tmux_tpm
  install_zellij_plugins
  link_dotfiles
  start_services

  log "Done. Backups, if any, are under: $BACKUP_DIR"
}

main
