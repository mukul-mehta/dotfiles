## `~/.zshrc`

# ~/.zshrc — interactive Zsh configuration for macOS
#
# Plugins:  Antidote
# History:  Atuin + native Zsh fallback
# Python:   uv
# Node:     NVS
# Go:       native/Homebrew Go
# Env vars: direnv

zmodload zsh/datetime
zmodload zsh/parameter

typeset -F __shell_start
__shell_start=$EPOCHREALTIME

# -----------------------------------------------------------------------------
# Base directories and environment
# -----------------------------------------------------------------------------

export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/Personal/dotfiles}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export ZSH_COMPLETION_DIR="$ZSH_CACHE_DIR/completions"
mkdir -p -- "$ZSH_CACHE_DIR/generated" "$ZSH_COMPLETION_DIR"

typeset -U path fpath

typeset -g HOMEBREW_PREFIX=""

if [[ -x /opt/homebrew/bin/brew ]]; then
  HOMEBREW_PREFIX=/opt/homebrew
elif [[ -x /usr/local/bin/brew ]]; then
  HOMEBREW_PREFIX=/usr/local
fi

export HOMEBREW_PREFIX

# Runtime/tool directories
export GOPATH="${GOPATH:-$HOME/go}"
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

typeset -a brew_paths
brew_paths=()

if [[ -n $HOMEBREW_PREFIX ]]; then
  brew_paths=(
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/sbin"
    "$HOMEBREW_PREFIX/opt/postgresql@15/bin"
    "$HOMEBREW_PREFIX/opt/mysql-client/bin"
  )
fi

path=(
  "$HOME/.local/bin"
  "/opt/zerobrew/prefix/bin"
  $brew_paths
  "$PNPM_HOME"
  "$BUN_INSTALL/bin"
  "$GOPATH/bin"
  "$HOME/.cargo/bin"
  "$HOME/.yarn/bin"
  "$HOME/.config/yarn/global/node_modules/.bin"
  "$HOME/.spicetify"
  "$HOME/.opencode/bin"
  $path
)

unset brew_paths

export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--FRX}"

export LANG="${LANG:-en_US.UTF-8}"
unset LC_ALL

if [[ -d "${VAPI_INSTALL:-$HOME/.vapi}/share/man" ]]; then
  export VAPI_INSTALL="${VAPI_INSTALL:-$HOME/.vapi}"
  export MANPATH="$VAPI_INSTALL/share/man:${MANPATH:-}"
fi

# -----------------------------------------------------------------------------
# Shell behaviour
# -----------------------------------------------------------------------------

setopt INTERACTIVE_COMMENTS
setopt MAGIC_EQUAL_SUBST
setopt NO_NOMATCH
setopt NOTIFY
setopt NUMERIC_GLOB_SORT
setopt PROMPT_SUBST
setopt EXTENDED_GLOB

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt NO_BEEP

# Treat `/` as a word boundary.
WORDCHARS=${WORDCHARS//\/}

# -----------------------------------------------------------------------------
# Native Zsh history
#
# Atuin is the primary interactive search interface. Native history remains a
# useful local fallback and powers normal Up/Down prefix search.
# -----------------------------------------------------------------------------

export HISTFILE="$XDG_CACHE_HOME/.zsh_history"

HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Native Zsh history exclusion pattern.
HISTORY_IGNORE='(exit|q|ls|ll|pwd|bg|fg|history|clear|dirs)'

# -----------------------------------------------------------------------------
# Line editor and key bindings
# -----------------------------------------------------------------------------

bindkey -e

bindkey ' ' magic-space
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[5~' beginning-of-buffer-or-history
bindkey '^[[6~' end-of-buffer-or-history
bindkey '^[[Z' undo

# Prefix-aware Up/Down history search.
# Atuin owns Ctrl-R only.
autoload -Uz history-search-end

zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end

# -----------------------------------------------------------------------------
# Completion paths
#
# Every completion directory must be in fpath before ez-compinit calls compinit.
# -----------------------------------------------------------------------------

fpath=(
  "$ZSH_COMPLETION_DIR"
  "$HOME/.zfunc"
  $fpath
)

if (( $+commands[zellij] )); then
  zellij_completion_file="$ZSH_COMPLETION_DIR/_zellij"
  zellij_completion_executable="${commands[zellij]}"
  zellij_completion_temporary="${zellij_completion_file}.tmp"

  if [[ ! -s $zellij_completion_file ||
        $zellij_completion_executable -nt $zellij_completion_file ]]; then
    if command zellij setup --generate-completion zsh >| "$zellij_completion_temporary" 2>/dev/null; then
      command mv -f -- "$zellij_completion_temporary" "$zellij_completion_file"
    else
      command rm -f -- "$zellij_completion_temporary"
    fi
  fi

  unset zellij_completion_file zellij_completion_executable zellij_completion_temporary
fi

if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=(
    "$HOME/.docker/completions"
    $fpath
  )
fi

# Bun installs its completion definition as ~/.bun/_bun.
if [[ -s "$BUN_INSTALL/_bun" ]]; then
  fpath=(
    "$BUN_INSTALL"
    $fpath
  )
fi

if [[ -n $HOMEBREW_PREFIX ]]; then
  fpath=(
    "$HOMEBREW_PREFIX/share/zsh/site-functions"
    $fpath
  )
fi

# -----------------------------------------------------------------------------
# Completion and plugin configuration
#
# These values must be set before Antidote loads the plugins.
# -----------------------------------------------------------------------------

export ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"

# ez-compinit will cache and compile the dump file.
zstyle ':plugin:ez-compinit' use-cache yes

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/completion-cache"

zstyle ':completion:*' completer \
  _complete \
  _match

zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*'

zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' squeeze-slashes true

# Preserve the order supplied by Git completion.
zstyle ':completion:*:git-checkout:*' sort false

# fzf-tab has its own options and does not need the global fzf configuration.
zstyle ':fzf-tab:*' fzf-flags \
  --height=60% \
  --layout=reverse \
  --border \
  --info=inline

zstyle ':fzf-tab:*' switch-group '<' '>'

if (( $+commands[eza] )); then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview \
    'eza --all --group-directories-first --color=always --icons=auto -- "$realpath" 2>/dev/null'

  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview \
    'eza --all --group-directories-first --color=always --icons=auto -- "$realpath" 2>/dev/null'
fi

# Atuin will add itself to this list when its shell integration is loaded.
ZSH_AUTOSUGGEST_STRATEGY=(
  history
)

ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  history-beginning-search-backward-end
  history-beginning-search-forward-end
)

# -----------------------------------------------------------------------------
# Antidote
# -----------------------------------------------------------------------------

export ANTIDOTE_HOME="${ANTIDOTE_HOME:-$XDG_CACHE_HOME/antidote}"
export ZSH_PLUGINS_FILE="${ZSH_PLUGINS_FILE:-${ZDOTDIR:-$HOME}/.zsh_plugins.txt}"

typeset -g ANTIDOTE_ZSH=""

if [[ -n $HOMEBREW_PREFIX ]] &&
   [[ -r "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]]; then
  ANTIDOTE_ZSH="$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
elif [[ -r "$HOME/.antidote/antidote.zsh" ]]; then
  ANTIDOTE_ZSH="$HOME/.antidote/antidote.zsh"
fi

if [[ -n $ANTIDOTE_ZSH ]]; then
  source "$ANTIDOTE_ZSH"

  if [[ -r $ZSH_PLUGINS_FILE ]]; then
    antidote load "$ZSH_PLUGINS_FILE"
  else
    print -u2 -- "Antidote plugin file not found: $ZSH_PLUGINS_FILE"
  fi
else
  print -u2 -- "Antidote is not installed. Run: brew install antidote"
fi

# -----------------------------------------------------------------------------
# Cached generated integrations
#
# Several CLI tools print a static Zsh integration script. Cache it rather than
# starting each executable for every new terminal tab.
# -----------------------------------------------------------------------------

_zsh_prepare_init() {
  emulate -L zsh

  local name="$1"
  shift

  local command_name="$1"
  local executable="${commands[$command_name]:-}"

  local cache_file="$ZSH_CACHE_DIR/generated/${name}.zsh"
  local signature_file="${cache_file}.command"
  local temporary_file="${cache_file}.tmp"
  local temporary_signature="${signature_file}.tmp"

  local signature="${(j: :)${(q)@}}"
  local old_signature=""

  [[ -n $executable ]] || return 1

  if [[ -r $signature_file ]]; then
    old_signature="$(<"$signature_file")"
  fi

  if [[ ! -s $cache_file ||
        $executable -nt $cache_file ||
        $signature != $old_signature ]]; then

    if "$@" >| "$temporary_file"; then
      print -r -- "$signature" >| "$temporary_signature"

      command mv -f -- "$temporary_file" "$cache_file"
      command mv -f -- "$temporary_signature" "$signature_file"
    else
      command rm -f -- "$temporary_file" "$temporary_signature"
      return 1
    fi
  fi

  typeset -g REPLY="$cache_file"
}

# -----------------------------------------------------------------------------
# fzf
# -----------------------------------------------------------------------------

# Keep fuzzy ranking. `--exact --no-sort` made file and directory searches much
# less useful.
export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border --cycle --info=inline'

if (( $+commands[fd] )); then
  export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
else
  export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!.git"'
fi

if (( $+commands[bat] )); then
  export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:500 -- {}"'
fi

if (( $+commands[eza] )); then
  export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --color=always --icons=auto -- {} | head -200"'
fi

# fzf binds Ctrl-T and Alt-C. Atuin is initialized afterwards and takes Ctrl-R.
if (( $+commands[fzf] )); then
  _zsh_prepare_init fzf fzf --zsh &&
    source "$REPLY"
fi

# -----------------------------------------------------------------------------
# Atuin, zoxide, and runtime integrations
# -----------------------------------------------------------------------------

if (( $+commands[atuin] )); then
  _zsh_prepare_init atuin atuin init zsh --disable-up-arrow &&
    source "$REPLY"
fi

if (( $+commands[zoxide] )); then
  _zsh_prepare_init zoxide zoxide init zsh &&
    source "$REPLY"
fi

# Python
#
# uv requires no persistent shell initialization. ~/.local/bin is already
# present in PATH.

# Node — lazy NVS loading.
#
# `nvs link <version>` should create ~/.nvs/default. That linked version is
# immediately available, while the full NVS script loads only when `nvs` is run.
export NVS_HOME="${NVS_HOME:-$HOME/.nvs}"

if [[ -s "$NVS_HOME/nvs.sh" ]]; then
  if [[ -d "$NVS_HOME/default/bin" ]]; then
    path=(
      "$NVS_HOME/default/bin"
      $path
    )

    nvs() {
      unset -f nvs
      source "$NVS_HOME/nvs.sh"
      nvs "$@"
    }
  else
    # No linked default exists, so load NVS normally to keep Node usable.
    source "$NVS_HOME/nvs.sh"
  fi
fi

# Go
#
# Do not set GOROOT manually; the installed Go executable determines it.
export GOPATH="${GOPATH:-$HOME/go}"

# Global private values are loaded before direnv so project .envrc files can
# override them.
if [[ -r "$HOME/.env.private" ]]; then
  source "$HOME/.env.private"
fi

if (( $+commands[direnv] )); then
  _zsh_prepare_init direnv direnv hook zsh &&
    source "$REPLY"
fi

# -----------------------------------------------------------------------------
# Additional command completions
# -----------------------------------------------------------------------------

# AWS and Terraform expose Bash-compatible completion commands.
if (( $+commands[aws_completer] || $+commands[terraform] )); then
  autoload -Uz bashcompinit
  bashcompinit

  if (( $+commands[aws_completer] )); then
    complete -C "${commands[aws_completer]}" aws
  fi

  if (( $+commands[terraform] )); then
    complete -o nospace -C "${commands[terraform]}" terraform
  fi
fi

if (( $+commands[bhatti] )); then
  _zsh_prepare_init bhatti bhatti completion zsh &&
    source "$REPLY"
fi

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

# Pretty list of listening TCP sockets.
listening() {
  command lsof -nP -iTCP -sTCP:LISTEN |
    tail -n +2 |
    awk '
      {
        red = "\033[01;31m"
        clear = "\033[0m"

        printf "%sproto: %stcp%d %saddr.port: %s%s %spid: %s%s %sname: %s%s\n",
          red, clear, ($8 == "IPv6" ? 6 : 4),
          red, clear, $9,
          red, clear, $2,
          red, clear, $1
      }
    ' |
    column -t |
    sort -u
}

# Interactively select processes.
#
#   kp       -> SIGTERM
#   kp KILL  -> SIGKILL
#   kp HUP   -> SIGHUP
kp() {
  emulate -L zsh

  local signal="${1:-TERM}"
  local selection

  selection="$(
    command ps -Ao pid=,user=,etime=,command= |
      fzf \
        --multi \
        --height=60% \
        --layout=reverse \
        --border \
        --header="TAB: select • ENTER: send SIG${signal}" \
        --preview='ps -p {1} -o pid,ppid,user,%cpu,%mem,etime,command'
  )" || return 0

  [[ -n $selection ]] || return 0

  local -a pids
  pids=("${(@f)$(print -r -- "$selection" | awk '{print $1}')}")

  command kill "-$signal" "${pids[@]}"
}

function pubkey {
  emulate -L zsh

  local key="${1:-$HOME/.ssh/id_ed25519.pub}"

  if [[ ! -r $key ]]; then
    print -u2 -- "Public key not found: $key"
    return 1
  fi

  command pbcopy < "$key"
  print -- "Public key copied: $key"
}

mkcd() {
  if [[ -z $1 ]]; then
    print -u2 -- "Usage: mkcd <directory>"
    return 2
  fi

  command mkdir -p -- "$1" &&
    builtin cd -- "$1"
}

zreload() {
  exec zsh
}

function hermes-sh() {
  kubectl -n hermes exec -it deploy/hermes -- bash
}

function hermes() {
  kubectl -n hermes exec -it deploy/hermes -- hermes "$@"
}


# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------

if [[ -r "$DOTFILES_ROOT/zsh/aliases.zsh" ]]; then
  source "$DOTFILES_ROOT/zsh/aliases.zsh"
fi

# -----------------------------------------------------------------------------
# Prompt
# -----------------------------------------------------------------------------

if (( $+commands[starship] )); then
  _zsh_prepare_init starship starship init zsh &&
    source "$REPLY"
fi

# The helper is no longer needed after initialization.
unfunction _zsh_prepare_init 2>/dev/null

if (( $+EPOCHREALTIME )) && [[ -n ${__shell_start:-} ]]; then
  printf 'ZSH Startup took %.0f ms\n' \
    "$(( (EPOCHREALTIME - __shell_start) * 1000 ))"
fi
