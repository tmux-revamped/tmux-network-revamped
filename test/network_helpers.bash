#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  for name in $(compgen -v NETWORK_REVAMPED_); do
    unset "${name}"
  done
  FAKE="${BATS_TEST_TMPDIR}/fake"
  export HOME="${BATS_TEST_TMPDIR}/home" FAKE
  mkdir -p "${HOME}" "${FAKE}" "${BATS_TEST_TMPDIR}/stubs"
  UNTRACED='{ set +x; } 2>/dev/null'
  printf '3.6\n' >"${FAKE}/version"
  : >"${FAKE}/vars"
  : >"${FAKE}/log"
  : >"${FAKE}/asked"
  now 1000000
  fake_tmux
  fake_date
  linux
  harness_hide route ip netstat ipconfig scutil system_profiler nmcli iwgetid iw ping curl ss perl
}

quiet() {
  printf '#!/bin/sh\n%s\n%s\n' "${UNTRACED}" "$2" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

var() {
  local kept
  kept=$(grep -v "^$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "${kept}" "$1" "$2" | grep -v '^$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}

value() {
  awk -F '\t' -v want="$1" '$1 == want { print $2 }' "${FAKE}/vars"
}

option() {
  var "@net_revamped_$1" "$2"
}

held() {
  value "@net_revamped_$1"
}

now() {
  printf '%s\n' "$1" >"${FAKE}/now"
}

fake_date() {
  quiet date 'case "${1:-}" in
+%s%N)
  if [ -f "'"${FAKE}"'/now_ns" ]; then
    cat "'"${FAKE}"'/now_ns"
  else
    IFS= read -r seconds <"'"${FAKE}"'/now"
    printf "%sN\n" "${seconds}"
  fi
  ;;
*) cat "'"${FAKE}"'/now" ;;
esac'
}

macos() {
  export REVAMPED_TEST_UNAME_S=Darwin
}

linux() {
  export REVAMPED_TEST_UNAME_S=Linux
}

says() {
  printf '%s\n' "$2" >"${FAKE}/$1.out"
  quiet "$1" 'printf "%s %s\n" "'"$1"'" "$*" >>"'"${FAKE}"'/asked"; cat "'"${FAKE}/$1"'.out"'
}

route_is() {
  says route "   route to: default
  interface: $1
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>"
}

netstat_says() {
  printf '%s\n' "$2" >"${FAKE}/netstat.$1"
  quiet netstat 'printf "netstat %s\n" "$*" >>"'"${FAKE}"'/asked"
case "$*" in
-ib) kind=counters ;;
"-rn -f inet") kind=routes ;;
*) kind=sockets ;;
esac
[ ! -f "'"${FAKE}"'/netstat.${kind}" ] || cat "'"${FAKE}"'/netstat.${kind}"'
}

counters_macos() {
  netstat_says counters "Name       Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
lo0        16384 <Link#1>                        1000     0     900000     1000     0     900000     0
$1        1500  <Link#12>   aa:bb:cc:dd:ee:ff     2000     0   $2     1500     0   $3     0"
}

ip_says() {
  printf '%s\n' "$2" >"${FAKE}/ip.$1"
  quiet ip 'printf "ip %s\n" "$*" >>"'"${FAKE}"'/asked"
case "$1" in
route) kind=route ;;
addr) kind=addr ;;
*) kind=links ;;
esac
[ ! -f "'"${FAKE}"'/ip.${kind}" ] || cat "'"${FAKE}"'/ip.${kind}"'
}

proc_file() {
  printf '%s\n' "$2" >"${FAKE}/proc.$1"
  quiet cat 'case "$1" in
/proc/net/dev) name=dev ;;
/proc/net/wireless) name=wireless ;;
*) exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "$@" ;;
esac
[ -f "'"${FAKE}"'/proc.${name}" ] || exit 1
exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "'"${FAKE}"'/proc.${name}"'
}

counters_linux() {
  proc_file dev "Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:  900000    1000    0    0    0     0          0         0   900000    1000    0    0    0     0       0          0
  $1: $2    2000    0    0    0     0          0         0 $3    1500    0    0    0     0       0          0"
}

curl_says() {
  printf '%s\n' "$1" >"${FAKE}/curl.address"
  printf '%s\n' "${2:-0}" >"${FAKE}/curl.reach"
  quiet curl 'printf "curl %s\n" "$*" >>"'"${FAKE}"'/asked"
case "$*" in
*generate_204*)
  IFS= read -r code <"'"${FAKE}"'/curl.reach"
  exit "${code}"
  ;;
*) cat "'"${FAKE}"'/curl.address" ;;
esac'
}

clock_ns() {
  printf '%s\n' "$1" >"${FAKE}/now_ns"
}

sampled() {
  option download "${1:-1.0KB/s}"
  option upload "${2:-512B/s}"
  option total "${3:-1536}"
  option down_smooth 1024
  option up_smooth 512
  option rx_raw 5000000
  option tx_raw 3000000
  option sample_ms 1000000000
  option download_ts "${4:-1000000}"
}

asked() {
  cat "${FAKE}/asked"
}

fake_tmux() {
  cat >"${BATS_TEST_TMPDIR}/stubs/tmux" <<EOF
#!/bin/sh
${UNTRACED}
printf '%s\n' "\$*" >>"${FAKE}/log"
expanded() {
  printf '%s\n' "\$1" | awk -v vars="${FAKE}/vars" '
    BEGIN { while ((getline row < vars) > 0) { at = index(row, "\t"); value[substr(row, 1, at - 1)] = substr(row, at + 1) } }
    {
      line = \$0
      out = ""
      while ((at = index(line, "#{")) > 0) {
        stop = index(substr(line, at), "}")
        name = substr(line, at + 2, stop - 3)
        out = out substr(line, 1, at - 1) value[name]
        line = substr(line, at + stop)
      }
      print out line
    }
  '
}
looked() {
  awk -F '\t' -v want="\$1" '\$1 == want { print \$2 }' "${FAKE}/vars"
}
put() {
  kept=\$(grep -v "^\$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "\${kept}" "\$1" "\$2" | grep -v '^\$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}
written() {
  while [ "\$#" -gt 0 ]; do
    if [ "\$1" = set-option ] && [ "\${2:-}" = -gq ] && [ "\$#" -ge 4 ]; then
      put "\$3" "\$4"
      shift 4
      continue
    fi
    shift
  done
}
case "\$1" in
-V)
  IFS= read -r version <"${FAKE}/version"
  printf 'tmux %s\n' "\${version}"
  ;;
display-message)
  [ "\$2" != -p ] || expanded "\$3"
  ;;
show-option)
  looked "\$3"
  ;;
list-keys)
  [ ! -f "${FAKE}/keys" ] || cat "${FAKE}/keys"
  ;;
list-clients)
  [ ! -f "${FAKE}/clients" ] || cat "${FAKE}/clients"
  ;;
*)
  case "\$*" in
  *" ; "*) [ ! -f "${FAKE}/refused" ] || exit 1 ;;
  *) [ ! -f "${FAKE}/refused" ] || ! grep -qF -- "\$*" "${FAKE}/refused" || exit 1 ;;
  esac
  written "\$@"
  ;;
esac
exit 0
EOF
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

tmux_is() {
  printf '%s\n' "$1" >"${FAKE}/version"
}

planned() {
  lib_run network "${1:-}"'network_revamped_plan; network_revamped_lines'
}

sends() {
  grep -v -e '^display-message -p' -e '^-V' -e '^list-' -e '^show-option' "${FAKE}/log" || :
}

sent() {
  grep -c -- "$1" "${FAKE}/log" || :
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/network-revamped" "$@"
}

tool_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR}/../bin/network-revamped"
}

bin_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR%/test}/bin/network-revamped"
}

has_line() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" == "$1" ]] && return 0
  done
  return 1
}

answers() {
  export REVAMPED_TEST_GUM_ANSWERS="${BATS_TEST_TMPDIR}/answers"
  printf '%s\n' "$@" >"${REVAMPED_TEST_GUM_ANSWERS}"
}

said() {
  grep -qxF -- "display-message network-revamped: $1" "${FAKE}/log"
}

eventually() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@"
}

holds() {
  local now
  now=$(held "$1")
  [[ "${now}" == "$2" ]]
}
