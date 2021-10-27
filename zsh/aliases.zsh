# Changing directory
alias ..='z ..'
alias ...='z ../..'
alias ....='z ../../..'
alias cs="z ~/CS"
alias acad="z ~/Academic"
alias dl="z ~/Downloads"
alias bd="z ~/Random/Software"
alias ms="cd ~/CS/Misc"

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

alias ys="yarn start"