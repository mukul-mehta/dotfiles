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
alias dlf="docker logs -f"

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

if (( $+commands[zellij] )); then
    # Full Zellij command.
    alias zj="zellij"

    # Attach to an existing session:
    #   za routeup
    unalias za 2>/dev/null
    function za() {
        command zellij attach "$@"
    }

    # List sessions:
    #   zls
    alias zls="zellij list-sessions"

    # Create or attach to a named session.
    #
    # Usage:
    #   zn <session>
    #   zn <session> --layout <layout>
    #   zn --layout <layout> <session>
    #
    # Examples:
    #   zn scratch
    #   zn routeup --layout personal
    #   zn zepl --layout zepl
    function zn() {
        local session=""
        local layout=""

        while (( $# > 0 )); do
            case "$1" in
                -l|--layout)
                    if (( $# < 2 )); then
                        print -u2 "zn: --layout requires a layout name"
                        return 2
                    fi

                    layout="${2%.kdl}"
                    shift 2
                    ;;

                -h|--help)
                    print "usage: zn <session-name> [-l|--layout <layout-name>]"
                    print
                    print "examples:"
                    print "  zn scratch"
                    print "  zn routeup --layout personal"
                    print "  zn zepl -l zepl"
                    return 0
                    ;;

                -*)
                    print -u2 "zn: unknown option: $1"
                    return 2
                    ;;

                *)
                    if [[ -n "$session" ]]; then
                        print -u2 "zn: only one session name may be provided"
                        return 2
                    fi

                    session="$1"
                    shift
                    ;;
            esac
        done

        if [[ -z "$session" ]]; then
            print -u2 "usage: zn <session-name> [-l|--layout <layout-name>]"
            return 2
        fi

        if [[ -n "$layout" ]]; then
            local config_dir="${ZELLIJ_CONFIG_DIR:-$HOME/.config/zellij}"
            local layout_file="$config_dir/layouts/$layout.kdl"

            if [[ ! -f "$layout_file" ]]; then
                print -u2 "zn: layout not found: $layout_file"
                return 1
            fi

            command zellij attach --create "$session" \
                options --default-layout "$layout"
        else
            command zellij attach --create "$session"
        fi
    }

    function _zellij_session_names() {
        local -a sessions

        sessions=("${(@f)$(command zellij list-sessions --short --no-formatting 2>/dev/null)}")

        (( $#sessions )) &&
            _describe -t zellij-sessions "zellij sessions" sessions
    }

    function _zellij_layout_names() {
        local config_dir="${ZELLIJ_CONFIG_DIR:-$HOME/.config/zellij}"
        local -a layouts

        layouts=("$config_dir"/layouts/*.kdl(N:t:r))

        (( $#layouts )) &&
            _describe -t zellij-layouts "zellij layouts" layouts
    }

    function _za() {
        _arguments -C \
            '(-c --create)'{-c,--create}'[Create a session if one does not exist]' \
            '(-b --create-background)'{-b,--create-background}'[Create a detached session in the background if one does not exist]' \
            '(-f --force-run-commands)'{-f,--force-run-commands}'[Immediately run commands when resurrecting a dead session]' \
            '(-r --remember)'{-r,--remember}'[Save session for automatic re-authentication]' \
            '--forget[Delete saved session before connecting]' \
            '--insecure[Skip TLS certificate validation]' \
            '--index=[Attach by session index]:index:' \
            '(-t --token)'{-t,--token}'=[Authentication token for remote sessions]:token:' \
            '--ca-cert=[Path to a custom CA certificate]:file:_files' \
            '::session name:_zellij_session_names'
    }

    function _zls() {
        _arguments -C \
            '(-n --no-formatting)'{-n,--no-formatting}'[Do not add colors or formatting]' \
            '(-s --short)'{-s,--short}'[Print just the session name]' \
            '(-r --reverse)'{-r,--reverse}'[List sessions in reverse order]' \
            '(-h --help)'{-h,--help}'[Print help information]'
    }

    function _zn() {
        _arguments -C \
            '(-l --layout)'{-l,--layout}'[Use a Zellij layout]:layout:_zellij_layout_names' \
            '(-h --help)'{-h,--help}'[Show help]' \
            '1:session name:_zellij_session_names'
    }

    if (( $+functions[compdef] )); then
        autoload -Uz _zellij 2>/dev/null

        compdef _zellij zellij zj
        compdef _za za
        compdef _zls zls
        compdef _zn zn
    fi
fi
