_normal=$'\e[0m'
_color=$'\e[1;32m'
_symbol='$'
PS1="\[$_color\]\w\[\e[2;37m\]$_symbol \[$_normal\]"
unset _normal _color _symbol
