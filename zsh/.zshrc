# __shell_start=`/usr/local/Cellar/coreutils/8.32/bin/gdate +%s%3N`
if [ -x /usr/libexec/path_helper ]; then
  eval `/usr/libexec/path_helper -s`
fi

# ~/.zshrc file for zsh non-login shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

# Enable brew completions
if type brew &>/dev/null; then
  FPATH=/usr/local/share/zsh/site-functions:$FPATH
fi

setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[Z' undo                               # shift + tab undo last action

# better search defaults
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end  # up to search history
bindkey "^[[B" history-beginning-search-forward-end   # down to search history


zstyle ':completion:*:*:*:*:*' menu yes select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# history configurations
HISTFILE=~/.cache/.zsh_history
HISTSIZE=1000
SAVEHIST=10000
HISTORY_IGNORE="(exit|ls|pwd|bg|fg|history|clear|dir)"
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cs="cd ~/CS"
alias acad="cd ~/Academic"
alias dl="cd ~/Downloads"
alias bd="cd ~/Random/Software"
alias q='exit'

if type tty-clock &>/dev/null; then
  alias clk='tty-clock -b -c -C 2'
fi


if type lsd &>/dev/null; then
	alias ls="lsd --group-dirs first"
	alias tree="lsd --tree"
fi

if type bat &>/dev/null;then
	alias cat="bat"
elif type batcat &>/dev/null;then
	alias cat="batcat"
fi

if type tmux &>/dev/null;then
	alias t="tmux"
	alias ta="t a -t"
	alias tls="t ls"
	alias tn="t new -t"
fi

alias code="code-insiders"
alias ms="cd ~/CS/Misc"
alias dc="docker-compose"

# enable syntax-highlighting
if [ -f ~/.scripts/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
	. ~/.scripts/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
fi

# enable auto-suggestions
if [ -f ~/.scripts/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
	. ~/.scripts/zsh-autosuggestions/zsh-autosuggestions.zsh
	ZSH_AUTOSUGGEST_STRATEGY=(history completion)
	# https://github.com/zsh-users/zsh-autosuggestions/issues/619
	ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(history-beginning-search-backward-end history-beginning-search-forward-end)
fi

# Enable FZF and set some FZF options
[ -f ~/.scripts/fzf.zsh ] && source ~/.scripts/fzf.zsh
export FZF_DEFAULT_OPTS='--exact --no-sort --reverse --cycle --height 40%'
export FZF_CTRL_T_COMMAND='rg --files -. -L -g "!{.git}"'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --line-range=:500 {}"'

export PATH="$HOME/.local/bin:$PATH"
export EDITOR="vim"
export LC_ALL=en_US.UTF-8

# Enable pyenv and friends
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Enable NVM and source completions
function init_nvm() {
	export NVM_DIR=~/.nvm
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
}

# Kill process
function kp() {
	FZF_DEFAULT_COMMAND='ps -erf' \
	fzf --bind 'ctrl-r:reload(ps -erf)' \
		--header 'Press Ctrl + R to Reload' \
		--header-lines=1 --multi --height=50% \
		--layout=reverse | awk '{print $2}' | xargs kill -9
}

# List open ports with netstat
function listening(){
    netstat -Watnlv | grep LISTEN | \
    awk '{"ps -o comm= -p " $9 | getline procname;colred="\033[01;31m";colclr="\033[0m"; print colred "proto: " colclr $1 colred " | addr.port: " colclr $4 colred " | pid: " colclr $9 colred " | name: " colclr procname;  }' | column -t -s "|" | sort
}

# Go specific settings
export GOPATH=$HOME/go
export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# Needed for signging commits since it needs a TTY for password prompt
export GPG_TTY=$(tty)

# enable Starship prompt
eval "$(starship init zsh)"

# enable completion features
autoload -Uz compinit
if [ $(date +'%j') != $(/usr/bin/stat -f '%Sm' -t '%j' ${ZDOTDIR:-$HOME}/.cache/zcompdump) ]; then
  compinit -d ~/.cache/zcompdump
else
  compinit -d ~/.cache/zcompdump -C
fi

if [[ -v __shell_start ]]; then
  echo -e "\nLoading personal and system profiles took $((`/usr/local/Cellar/coreutils/8.32/bin/gdate +%s%3N`-__shell_start))ms."
fi
