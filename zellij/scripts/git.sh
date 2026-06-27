#!/bin/zsh

branch=$(/usr/bin/git branch --show-current 2>/dev/null)

if [[ -n "$branch" ]]; then
    print -r -- " $branch"
fi
