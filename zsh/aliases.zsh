# Changing directory
alias ..='z ..'
alias ...='z ../..'
alias ....='z ../../..'
alias cs="z ~/Personal"
alias acad="z ~/Academic"
alias dl="z ~/Downloads"
alias bd="z ~/Random/Software"
alias ms="cd ~/Personal/Misc"

alias q='exit'
alias k="kubectl"
alias afk="open -a /System/Library/CoreServices/ScreenSaverEngine.app"
alias pubkey="more ~/.ssh/id_rsa.pub | pbcopy | echo '=> Public key copied to pasteboard.'"

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
alias dc="docker-compose"

alias gl="git log"
alias gsm="git switch main"
alias grm="git rebase main"
alias grc="git rebase --continue"

alias y="yarn"
alias yd="yarn dev"
alias yl="yarn local"
alias ynx="yarn nx run"
alias ys="yarn start"

alias n="nomad"
alias nj="nomad job"
alias njr="nomad job run"
alias njs="nomad job stop -purge"
alias ngc="nomad system gc"
