#!/bin/bash

alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias l='ls -A' # ls -CF # ls -aF1 | grep -v "^\..*" //  | grep -v \\._
alias la="ls -ahl"
function mkcd() { mkdir "$@" && cd "$@"; }
alias push="pushd"
alias pop="pushd +1"
