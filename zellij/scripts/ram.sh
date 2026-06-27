#!/bin/zsh

total_bytes=$(sysctl -n hw.memsize)

vm_stat | /usr/bin/awk -v total="$total_bytes" '
    /^Pages active:/                 { gsub(/\./, "", $3); active=$3 }
    /^Pages wired down:/             { gsub(/\./, "", $4); wired=$4 }
    /^Pages occupied by compressor:/ { gsub(/\./, "", $5); comp=$5 }
    END {
        page = 4096
        used = (wired + active + comp) * page
        printf "%.1f/%.0fGB\n", used/1073741824, total/1073741824
    }
'
