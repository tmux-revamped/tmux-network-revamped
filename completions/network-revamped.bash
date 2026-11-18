# shellcheck shell=bash
# shellcheck disable=SC2207

_network_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  status)
    COMPREPLY=($(compgen -W "download upload speed fg_color bg_color vpn vpn_name ip wifi ssid connections ping public_ip online" -- "${cur}"))
    return
    ;;
  --precision)
    COMPREPLY=($(compgen -W "0 1 2 3 4 5 6 7 8 9" -- "${cur}"))
    return
    ;;
  --render)
    COMPREPLY=($(compgen -W "jobs options" -- "${cur}"))
    return
    ;;
  --ping-enabled | --public-ip-enabled | --online-enabled)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --icons)
    COMPREPLY=($(compgen -W "ascii nerd" -- "${cur}"))
    return
    ;;
  --fixed-width)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --popup-key | --interface | --interval | --smoothing | --vpn-interval | --vpn-name-interval | --ip-interval | --connections-interval | --wifi-interval | --ssid-interval | --online-interval | --ping-interval | --public-ip-interval | --speed-format | --ping-format | --wifi-format | --online-up-text | --online-down-text | --download-label | --upload-label | --speed-label | --vpn-label | --vpn-name-label | --ip-label | --wifi-label | --ssid-label | --connections-label | --ping-label | --public-ip-label | --online-label | --download-width | --upload-width | --speed-width | --vpn-width | --vpn-name-width | --ip-width | --wifi-width | --ssid-width | --connections-width | --ping-width | --public-ip-width | --online-width | --medium-thresh | --high-thresh | --low-fg-color | --medium-fg-color | --high-fg-color | --low-bg-color | --medium-bg-color | --high-bg-color)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list status refresh card popup daemon doctor version help --json --theme --popup-key --interface --interval --precision --smoothing --render --ping-enabled --public-ip-enabled --online-enabled --vpn-interval --vpn-name-interval --ip-interval --connections-interval --wifi-interval --ssid-interval --online-interval --ping-interval --public-ip-interval --speed-format --ping-format --wifi-format --online-up-text --online-down-text --icons --fixed-width --download-label --upload-label --speed-label --vpn-label --vpn-name-label --ip-label --wifi-label --ssid-label --connections-label --ping-label --public-ip-label --online-label --download-width --upload-width --speed-width --vpn-width --vpn-name-width --ip-width --wifi-width --ssid-width --connections-width --ping-width --public-ip-width --online-width --medium-thresh --high-thresh --low-fg-color --medium-fg-color --high-fg-color --low-bg-color --medium-bg-color --high-bg-color" -- "${cur}"))
}

complete -F _network_revamped network-revamped
