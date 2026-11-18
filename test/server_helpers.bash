#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

screens() {
  printf 'host screen:\n'
  command tmux -S "${HOST}" capture-pane -p -t host || :
  printf 'options:\n'
  tmux show-options -g | grep net_revamped || :
  printf 'messages:\n'
  tmux show-messages | tail -n 5 || :
}

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  screens
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

holds() {
  local now
  now=$(tmux show-option -gqv "@net_revamped_$1")
  [[ "${now}" == "$2" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

host_lacks() {
  ! host_shows "$1"
}

said() {
  local messages
  messages=$(tmux show-messages)
  [[ "${messages}" == *"network-revamped: $1"* ]]
}

stand_in() {
  printf '#!/bin/sh\n%s\n' "$2" >"${STUBS}/$1"
  chmod +x "${STUBS}/$1"
}

network() {
  printf '1000000010\n' >"${BATS_TEST_TMPDIR}/clock"
  stand_in date 'case "${1:-}" in
+%s%N)
  IFS= read -r tick <"'"${BATS_TEST_TMPDIR}"'/clock"
  tick=$((tick + 2))
  printf "%s\n" "${tick}" >"'"${BATS_TEST_TMPDIR}"'/clock.next"
  mv -f "'"${BATS_TEST_TMPDIR}"'/clock.next" "'"${BATS_TEST_TMPDIR}"'/clock"
  printf "%s000000000\n" "${tick}"
  ;;
+%s)
  IFS= read -r tick <"'"${BATS_TEST_TMPDIR}"'/clock"
  printf "%s\n" "$((tick + 2))"
  ;;
*) exec "'"${BATS_TEST_TMPDIR}"'/farm/date" "$@" ;;
esac'
  stand_in route 'printf "   route to: default\n  interface: test0\n"'
  stand_in ip 'case "$1" in
route) printf "default via 192.168.0.1 dev test0 proto dhcp\n" ;;
addr) printf "    inet 10.0.0.7/24 brd 10.0.0.255 scope global dynamic test0\n" ;;
*) : ;;
esac'
  stand_in ipconfig 'printf "10.0.0.7\n"'
  stand_in netstat 'IFS= read -r tick <"'"${BATS_TEST_TMPDIR}"'/clock"
case "$*" in
-ib) printf "Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll\ntest0 1500 <Link#12> aa:bb:cc:dd:ee:ff 2000 0 %s 1500 0 %s 0\n" "$((tick * 102400))" "$((tick * 25600))" ;;
*) : ;;
esac'
  stand_in cat 'case "$1" in
/proc/net/dev)
  IFS= read -r tick <"'"${BATS_TEST_TMPDIR}"'/clock"
  printf "Inter-|   Receive |  Transmit\n face |bytes packets|bytes packets\n test0: %s 2000 0 0 0 0 0 0 %s 1500 0 0 0 0 0 0\n" "$((tick * 102400))" "$((tick * 25600))"
  ;;
/proc/net/wireless) printf "Inter-| sta-|   Quality\n face | tus | link level noise\n test0: 0000   58.  -52.  -256\n" ;;
*) exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "$@" ;;
esac'
  stand_in system_profiler 'printf "Wi-Fi:\n          Current Network Information:\n            Cafe #S:\n              Signal / Noise: -52 dBm / -95 dBm\n"'
  stand_in iwgetid 'printf "Cafe #S\n"'
}

without_tools() {
  local farm="${BATS_TEST_TMPDIR}/farm" folder name
  mkdir -p "${farm}"
  local IFS=:
  for folder in ${PATH}; do
    [[ -d "${folder}" ]] || continue
    ln -s "${folder}"/* "${farm}/" 2>/dev/null || :
  done
  unset IFS
  for name in route ip netstat ipconfig scutil system_profiler nmcli iwgetid iw ping curl ss; do
    rm -f "${farm:?}/${name}"
  done
  PATH="${STUBS}:${farm}"
}

setup() {
  unset BASH_ENV
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  without_tools
  network
  setup_tmux_server
  HOST="${TMUX_SOCKET}-host"
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux respawn-pane -k -t test:0.0 "env PS1='$ ' sh"
  tmux set-option -g status-interval 1
  tmux set-option -g status-left ''
  tmux set-option -g status-right-length 120
  tmux set-option -g @net_revamped_interval 1
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 30 \
    "env -u TMUX TERM=xterm-256color tmux -u -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
}

teardown() {
  local daemon
  daemon=$(tmux show-option -gqv @net_revamped_ticker_pid 2>/dev/null) || daemon=""
  if [[ "${daemon}" =~ ^[0-9]+$ ]]; then
    pkill -P "${daemon}" 2>/dev/null || :
    kill "${daemon}" 2>/dev/null || :
  fi
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "${1:-${ROOT}}" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/network-revamped.tmux'"
}

setting() {
  set_option "@net_revamped_$1" "$2"
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

prefix_keys() {
  local table
  table=$(tmux list-keys -T prefix)
  awk '{ for (i = 1; i < NF; i++) { if ($i == "-T") { print $(i + 2); break } } }' <<<"${table}"
}
