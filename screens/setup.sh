export PS1='$ '
export PATH="/Users/Shared/demo/bin:/Users/Shared/demo/tmux-network-revamped/bin:${PATH}"
unset KODOUGU_THEME KODOUGU_ACCENT NETWORK_REVAMPED_THEME NETWORK_REVAMPED_ACCENT NO_COLOR
export HOME=/Users/Shared/demo/home
cd /Users/Shared/demo || return 1
printf '\033]2;demo\033\134'
clear
