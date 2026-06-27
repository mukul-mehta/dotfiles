#!/bin/zsh

cores=$(/usr/sbin/sysctl -n hw.logicalcpu)

usage=$(
    /bin/ps -A -o %cpu= |
        /usr/bin/awk -v cores="$cores" '
            { sum += $1 }
            END {
                if (cores > 0) {
                    usage = sum / cores
                    if (usage > 100) usage = 100
                    printf "%.0f%%\n", usage
                }
            }'
)

if [[ -n "$usage" ]]; then
    print -- "$usage"
else
    print -- "?"
fi
