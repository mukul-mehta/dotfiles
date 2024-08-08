__shell_start=`/usr/local/bin/gdate +%s%3N`
if [ -x /usr/libexec/path_helper ]; then
  eval `/usr/libexec/path_helper -s`
fi

fpath+=~/.zfunc/
export DOTFILES_ROOT="$HOME/CS/dotfiles"

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

autoload bashcompinit && bashcompinit
# enable completion features
autoload -Uz compinit
if [ $(date +'%j') != $(/usr/bin/stat -f '%Sm' -t '%j' ${ZDOTDIR:-$HOME}/.cache/zcompdump) ]; then
  compinit -d ~/.cache/zcompdump
else
  compinit -d ~/.cache/zcompdump -C
fi
complete -C /usr/local/aws-cli/aws_completer aws


export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

export NVS_HOME="$HOME/.nvs"
[ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"
# Added by serverless binary installer
export PATH="$HOME/.serverless/bin:$PATH"
eval "$(zoxide init zsh)"

# Source aliases
. "$DOTFILES_ROOT/zsh/aliases.zsh"

# Source Private Env if exists
if [ -f '/Users/mukul-mehta/.env.private' ]; then
	. '/Users/mukul-mehta/.env.private'
fi

export PATH=$PATH:/Users/mukul-mehta/.spicetify
export PATH="/usr/local/opt/postgresql@15/bin:$PATH"
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mukul-mehta/Software/ZIPs/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mukul-mehta/Software/ZIPs/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/mukul-mehta/Software/ZIPs/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/mukul-mehta/Software/ZIPs/google-cloud-sdk/completion.zsh.inc'; fi

eval "$(direnv hook zsh)"

export PATH="$PATH:$HOME/.cargo/bin"
if [[ -v __shell_start ]]; then
  echo -e "\nLoading personal and system profiles took $((`/usr/local/bin/gdate +%s%3N`-__shell_start))ms."
fi


autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform
export PATH="/usr/local/opt/mysql-client/bin:$PATH"

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
