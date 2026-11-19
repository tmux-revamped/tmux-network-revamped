#!/bin/sh

[ -n "${NETWORK_REVAMPED_NETWORK_LOADED:-}" ] && return 0
NETWORK_REVAMPED_NETWORK_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"
# shellcheck source=SCRIPTDIR/cache.sh
. "${REVAMPED_LIB}/cache.sh"
# shellcheck source=SCRIPTDIR/publish.sh
. "${REVAMPED_LIB}/publish.sh"
# shellcheck source=SCRIPTDIR/ticker.sh
. "${REVAMPED_LIB}/ticker.sh"

network_revamped_format() {
  printf '%s\n' "${NETWORK_REVAMPED_SETTINGS}" | awk -F '\t' -v live="${NETWORK_REVAMPED_LIVE}" '{ printf "%s#{@net_revamped_%s}", (NR > 1 ? "\t" : ""), $1 } END { count = split(live, name, " "); for (i = 1; i <= count; i++) { printf "\t#{@net_revamped_%s}", name[i] } }'
}

network_revamped_resolve() {
  env | NETWORK_REVAMPED_ROWS="${NETWORK_REVAMPED_SETTINGS}" NETWORK_REVAMPED_VALUES="$1" awk -v live="${NETWORK_REVAMPED_LIVE}" '
    BEGIN {
      count = split(ENVIRON["NETWORK_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["NETWORK_REVAMPED_VALUES"], given, "\t")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        if (at == 0) { at = length(rows[i]) + 1 }
        name[i] = substr(rows[i], 1, at - 1)
        value[i] = (given[i] != "") ? given[i] : substr(rows[i], at + 1)
        want["NETWORK_REVAMPED_" toupper(name[i])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) {
        value[want[key]] = substr($0, at + 1)
      }
    }
    END {
      for (i = 1; i <= count; i++) { print name[i] "\t" value[i] }
      extra = split(live, state, " ")
      for (i = 1; i <= extra; i++) { print state[i] "\t" given[count + i] }
    }
  '
}

network_revamped_setting_rows() {
  network_revamped_setting_rows_format=$(network_revamped_format)
  network_revamped_setting_rows_live=$(tmux display-message -p "${network_revamped_setting_rows_format}" 2>/dev/null) || network_revamped_setting_rows_live=""
  network_revamped_resolve "${network_revamped_setting_rows_live}"
}

network_revamped_load() {
  network_revamped_load_values=$(network_revamped_setting_rows)
  while IFS='	' read -r network_revamped_load_name network_revamped_load_value; do
    IFS= read -r "NETWORK_REVAMPED_S_${network_revamped_load_name}" <<EOF
${network_revamped_load_value}
EOF
  done <<EOF
${network_revamped_load_values}
EOF
}

network_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

network_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  network_revamped_version_ge_have="${1%%.*}"
  network_revamped_version_ge_want="${2%%.*}"
  [ "${network_revamped_version_ge_have}" -gt "${network_revamped_version_ge_want}" ] && return 0
  [ "${network_revamped_version_ge_have}" -eq "${network_revamped_version_ge_want}" ] || return 1
  network_revamped_version_ge_have="${1#*.}"
  network_revamped_version_ge_want="${2#*.}"
  [ "${network_revamped_version_ge_have%%.*}" -ge "${network_revamped_version_ge_want%%.*}" ]
}

network_revamped_emit() {
  for network_revamped_emit_arg in "$@"; do
    case "${network_revamped_emit_arg}" in
    *\;) network_revamped_emit_arg="${network_revamped_emit_arg%;}\\;" ;;
    *) ;;
    esac
    NETWORK_REVAMPED_PLAN="${NETWORK_REVAMPED_PLAN}${network_revamped_emit_arg:-${NETWORK_REVAMPED_EMPTY}}
"
  done
  NETWORK_REVAMPED_PLAN="${NETWORK_REVAMPED_PLAN}
"
}

network_revamped_literal() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "1s/^/'/" -e "\$s/\$/'/"
}

network_revamped_send() {
  set --
  network_revamped_send_sep=""
  while IFS= read -r network_revamped_send_line; do
    if [ -z "${network_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || network_revamped_send_sep=";"
      continue
    fi
    [ -z "${network_revamped_send_sep}" ] || set -- "$@" "${network_revamped_send_sep}"
    network_revamped_send_sep=""
    [ "${network_revamped_send_line}" != "${NETWORK_REVAMPED_EMPTY}" ] || network_revamped_send_line=""
    set -- "$@" "${network_revamped_send_line}"
  done <<PLAN
${NETWORK_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

network_revamped_send_each() {
  network_revamped_send_each_status=0
  set --
  while IFS= read -r network_revamped_send_each_line; do
    if [ -n "${network_revamped_send_each_line}" ]; then
      [ "${network_revamped_send_each_line}" != "${NETWORK_REVAMPED_EMPTY}" ] || network_revamped_send_each_line=""
      set -- "$@" "${network_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || network_revamped_send_each_status=1
    set --
  done <<PLAN
${NETWORK_REVAMPED_PLAN}
PLAN
  return "${network_revamped_send_each_status}"
}

network_revamped_deliver() {
  ! network_revamped_send || return 0
  network_revamped_send_each
}

network_revamped_lines() {
  printf '%s' "${NETWORK_REVAMPED_PLAN}" | awk -v empty="${NETWORK_REVAMPED_EMPTY}" '$0 == empty { $0 = "\"\"" } $0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

network_revamped_json() {
  printf '%s' "${NETWORK_REVAMPED_PLAN}" | awk -v empty="${NETWORK_REVAMPED_EMPTY}" '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    $0 == empty { $0 = "" }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

network_revamped_bindings() {
  printf '%s' "${NETWORK_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

network_revamped_setting_name() {
  network_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${NETWORK_REVAMPED_NAMES} " in
  *" ${network_revamped_setting_name_raw} "*) printf '%s\n' "${network_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

network_revamped_bind() {
  case "$1" in
  "" | off) return 0 ;;
  *) ;;
  esac
  network_revamped_bind_key="$1" network_revamped_bind_note="$2"
  shift 2
  set -- "${network_revamped_bind_key}" "$@"
  [ "${NETWORK_REVAMPED_NOTES}" != 1 ] || set -- -N "${network_revamped_bind_note}" "$@"
  network_revamped_emit bind-key "$@"
}

network_revamped_job_quote() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g' -e 's/%/%%/g' -e "1s/^/'/" -e "\$s/\$/'/"
}

network_revamped_carried() {
  network_revamped_carried_set=$(env | sed -n 's/^NETWORK_REVAMPED_\([A-Z_]*\)=\(.*\)$/\1 \2/p')
  [ -n "${network_revamped_carried_set}" ] || return 0
  printf '%s\n' "${network_revamped_carried_set}" | NETWORK_REVAMPED_WANTED="${NETWORK_REVAMPED_CARRIED}" awk '
    BEGIN { count = split(ENVIRON["NETWORK_REVAMPED_WANTED"], name, " "); for (i = 1; i <= count; i++) { wanted[toupper(name[i])] = i } }
    {
      key = $1
      if (!(key in wanted)) { next }
      given[wanted[key]] = 1
      value[wanted[key]] = substr($0, length(key) + 2)
    }
    END {
      for (i = 1; i <= count; i++) {
        if (!given[i]) { continue }
        flag = name[i]
        gsub(/_/, "-", flag)
        print flag "\t" value[i]
      }
    }
  '
}

network_revamped_tools() {
  network_revamped_tools_path="${REVAMPED_LIB%/lib}/bin/network-revamped"
  NETWORK_REVAMPED_TOOL=$(network_revamped_literal "${network_revamped_tools_path}")
  NETWORK_REVAMPED_JOB=$(network_revamped_job_quote "${network_revamped_tools_path}")
  network_revamped_tools_rows=$(network_revamped_carried)
  while IFS='	' read -r network_revamped_tools_flag network_revamped_tools_value; do
    [ -n "${network_revamped_tools_flag}" ] || continue
    NETWORK_REVAMPED_TOOL="${NETWORK_REVAMPED_TOOL} --${network_revamped_tools_flag} $(network_revamped_literal "${network_revamped_tools_value}")"
    NETWORK_REVAMPED_JOB="${NETWORK_REVAMPED_JOB} --${network_revamped_tools_flag} $(network_revamped_job_quote "${network_revamped_tools_value}")"
  done <<EOF
${network_revamped_tools_rows}
EOF
}

network_revamped_held() {
  tmux list-keys -T prefix 2>/dev/null | awk '
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-T") { at += 2 }
      key = $at
      if (key ~ /^\\./) { key = substr(key, 2) }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest " " $i }
      if (index(rest, "network-revamped") == 0) { printf "%s ", key }
    }
  '
}

network_revamped_doubled() {
  network_revamped_doubled_rest="$1" network_revamped_doubled_hash='#' NETWORK_REVAMPED_DOUBLED=""
  while [ "${network_revamped_doubled_rest}" != "${network_revamped_doubled_rest#*"${network_revamped_doubled_hash}"}" ]; do
    NETWORK_REVAMPED_DOUBLED="${NETWORK_REVAMPED_DOUBLED}${network_revamped_doubled_rest%%"${network_revamped_doubled_hash}"*}${network_revamped_doubled_hash}${network_revamped_doubled_hash}"
    network_revamped_doubled_rest="${network_revamped_doubled_rest#*"${network_revamped_doubled_hash}"}"
  done
  NETWORK_REVAMPED_DOUBLED="${NETWORK_REVAMPED_DOUBLED}${network_revamped_doubled_rest}"
}

network_revamped_say() {
  network_revamped_doubled "$1"
  tmux display-message "network-revamped: ${NETWORK_REVAMPED_DOUBLED}" 2>/dev/null || :
}

network_revamped_now() {
  NETWORK_REVAMPED_NOW=$(date +%s 2>/dev/null) || NETWORK_REVAMPED_NOW=0
}

network_revamped_version() {
  network_revamped_version_raw=$(tmux -V 2>/dev/null) || network_revamped_version_raw=""
  NETWORK_REVAMPED_TMUX=$(network_revamped_parse_version "${network_revamped_version_raw}")
}

network_revamped_number() {
  NETWORK_REVAMPED_NUMBER="$1"
  revamped_cache_is_number "$1" || NETWORK_REVAMPED_NUMBER="$2"
}

network_revamped_store() {
  network_revamped_emit set-option -gq "@net_revamped_$1" "$2"
  IFS= read -r "NETWORK_REVAMPED_S_$1" <<EOF
$2
EOF
}

network_revamped_clock() {
  network_revamped_clock_raw=$(date +%s%N 2>/dev/null) || network_revamped_clock_raw=""
  case "${network_revamped_clock_raw}" in
  *[!0-9]* | '') network_revamped_clock_coarse ;;
  ????????????????*)
    NETWORK_REVAMPED_MS="${network_revamped_clock_raw%??????}"
    NETWORK_REVAMPED_NOW="${NETWORK_REVAMPED_MS%???}"
    ;;
  *) network_revamped_clock_coarse ;;
  esac
}

network_revamped_clock_coarse() {
  NETWORK_REVAMPED_MS=""
  if revamped_has_command perl; then
    NETWORK_REVAMPED_MS=$(perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000' 2>/dev/null) || NETWORK_REVAMPED_MS=""
  fi
  if revamped_cache_is_number "${NETWORK_REVAMPED_MS}"; then
    NETWORK_REVAMPED_NOW="${NETWORK_REVAMPED_MS%???}"
    return 0
  fi
  network_revamped_now
  NETWORK_REVAMPED_MS="${NETWORK_REVAMPED_NOW}000"
}

network_revamped_route_macos() {
  route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }'
}

network_revamped_route_linux() {
  ip route show default 2>/dev/null | awk '{ for (i = 1; i < NF; i++) { if ($i == "dev") { print $(i + 1); exit } } }'
}

network_revamped_iface() {
  NETWORK_REVAMPED_IFACE="${NETWORK_REVAMPED_S_interface}"
  [ -z "${NETWORK_REVAMPED_IFACE}" ] || return 0
  if revamped_is_macos; then
    NETWORK_REVAMPED_IFACE=$(network_revamped_route_macos) || NETWORK_REVAMPED_IFACE=""
  else
    NETWORK_REVAMPED_IFACE=$(network_revamped_route_linux) || NETWORK_REVAMPED_IFACE=""
  fi
}

network_revamped_counters_macos() {
  network_revamped_counters_macos_raw=$(netstat -ib 2>/dev/null) || network_revamped_counters_macos_raw=""
  network_revamped_counters_macos_pair=$(printf '%s\n' "${network_revamped_counters_macos_raw}" | awk -v i="${NETWORK_REVAMPED_IFACE}" '$1 == i && NF >= 10 && $(NF - 4) ~ /^[0-9]+$/ && $(NF - 1) ~ /^[0-9]+$/ { print $(NF - 4) " " $(NF - 1); exit }')
  IFS=' ' read -r NETWORK_REVAMPED_RX NETWORK_REVAMPED_TX <<EOF
${network_revamped_counters_macos_pair}
EOF
}

network_revamped_counters_linux() {
  network_revamped_counters_linux_raw=$(cat /proc/net/dev 2>/dev/null) || network_revamped_counters_linux_raw=""
  # shellcheck disable=SC2034
  while IFS=' :' read -r network_revamped_counters_linux_name NETWORK_REVAMPED_RX network_revamped_counters_linux_skip network_revamped_counters_linux_skip network_revamped_counters_linux_skip network_revamped_counters_linux_skip network_revamped_counters_linux_skip network_revamped_counters_linux_skip network_revamped_counters_linux_skip NETWORK_REVAMPED_TX network_revamped_counters_linux_skip; do
    [ "${network_revamped_counters_linux_name}" != "${NETWORK_REVAMPED_IFACE}" ] || return 0
  done <<EOF
${network_revamped_counters_linux_raw}
EOF
  NETWORK_REVAMPED_RX="" NETWORK_REVAMPED_TX=""
}

network_revamped_counters() {
  NETWORK_REVAMPED_RX="" NETWORK_REVAMPED_TX=""
  [ -n "${NETWORK_REVAMPED_IFACE}" ] || return 0
  if revamped_is_macos; then
    network_revamped_counters_macos
  else
    network_revamped_counters_linux
  fi
}

network_revamped_rate() {
  NETWORK_REVAMPED_RATE=0
  revamped_cache_is_number "$1" || return 0
  revamped_cache_is_number "$2" || return 0
  revamped_cache_is_number "$3" || return 0
  [ "$3" -gt 0 ] || return 0
  [ "$1" -gt "$2" ] || return 0
  NETWORK_REVAMPED_RATE=$((($1 - $2) * 1000 / $3))
}

network_revamped_smooth() {
  NETWORK_REVAMPED_SMOOTH="$1"
  revamped_cache_is_number "$2" || return 0
  network_revamped_smooth_weight="${NETWORK_REVAMPED_S_smoothing}"
  while [ "${#network_revamped_smooth_weight}" -gt 1 ] && [ "${network_revamped_smooth_weight#0}" != "${network_revamped_smooth_weight}" ]; do
    network_revamped_smooth_weight="${network_revamped_smooth_weight#0}"
  done
  case "${network_revamped_smooth_weight}" in
  [1-9] | [1-9][0-9]) NETWORK_REVAMPED_SMOOTH=$((($2 * network_revamped_smooth_weight + $1 * (100 - network_revamped_smooth_weight)) / 100)) ;;
  *) return 0 ;;
  esac
}

network_revamped_precision() {
  case "${NETWORK_REVAMPED_S_precision}" in
  [0-9]) NETWORK_REVAMPED_PLACES="${NETWORK_REVAMPED_S_precision}" ;;
  *) NETWORK_REVAMPED_PLACES="${NETWORK_REVAMPED_DEFAULT_PRECISION}" ;;
  esac
}

network_revamped_rates() {
  LC_ALL=C awk -v down="$1" -v up="$2" -v p="$3" '
    function shown(b,    v, u, r, unit) {
      split("B KB MB GB TB", unit, " ")
      v = b
      u = 1
      while (u < 5) {
        r = (u == 1) ? int(v + 0.5) : sprintf("%." p "f", v) + 0
        if (r < 1000) { break }
        v = v / 1024
        u++
      }
      if (u == 1) { return sprintf("%dB/s", int(v + 0.5)) }
      return sprintf("%." p "f%s/s", v, unit[u])
    }
    BEGIN {
      print shown(down)
      print shown(up)
    }
  '
}

network_revamped_clear() {
  network_revamped_store download ""
  network_revamped_store upload ""
  network_revamped_store total ""
  network_revamped_store down_smooth ""
  network_revamped_store up_smooth ""
  network_revamped_store sample_ms ""
  network_revamped_store download_ts "${NETWORK_REVAMPED_NOW}"
}

network_revamped_sample() {
  network_revamped_counters
  if ! revamped_cache_is_number "${NETWORK_REVAMPED_RX}" || ! revamped_cache_is_number "${NETWORK_REVAMPED_TX}"; then
    network_revamped_clear
    return 0
  fi
  network_revamped_sample_down=0 network_revamped_sample_up=0
  if revamped_cache_is_number "${NETWORK_REVAMPED_S_sample_ms}"; then
    network_revamped_sample_span=$((NETWORK_REVAMPED_MS - NETWORK_REVAMPED_S_sample_ms))
    network_revamped_rate "${NETWORK_REVAMPED_RX}" "${NETWORK_REVAMPED_S_rx_raw}" "${network_revamped_sample_span}"
    network_revamped_sample_down="${NETWORK_REVAMPED_RATE}"
    network_revamped_rate "${NETWORK_REVAMPED_TX}" "${NETWORK_REVAMPED_S_tx_raw}" "${network_revamped_sample_span}"
    network_revamped_sample_up="${NETWORK_REVAMPED_RATE}"
  fi
  network_revamped_smooth "${network_revamped_sample_down}" "${NETWORK_REVAMPED_S_down_smooth}"
  network_revamped_sample_down="${NETWORK_REVAMPED_SMOOTH}"
  network_revamped_smooth "${network_revamped_sample_up}" "${NETWORK_REVAMPED_S_up_smooth}"
  network_revamped_sample_up="${NETWORK_REVAMPED_SMOOTH}"
  network_revamped_precision
  network_revamped_sample_text=$(network_revamped_rates "${network_revamped_sample_down}" "${network_revamped_sample_up}" "${NETWORK_REVAMPED_PLACES}") || network_revamped_sample_text=""
  network_revamped_sample_first="${network_revamped_sample_text%%"${REVAMPED_PUBLISH_NEWLINE}"*}"
  network_revamped_sample_second="${network_revamped_sample_text#*"${REVAMPED_PUBLISH_NEWLINE}"}"
  network_revamped_store download "${network_revamped_sample_first}"
  network_revamped_store upload "${network_revamped_sample_second}"
  network_revamped_store total "$((network_revamped_sample_down + network_revamped_sample_up))"
  network_revamped_store down_smooth "${network_revamped_sample_down}"
  network_revamped_store up_smooth "${network_revamped_sample_up}"
  network_revamped_store rx_raw "${NETWORK_REVAMPED_RX}"
  network_revamped_store tx_raw "${NETWORK_REVAMPED_TX}"
  network_revamped_store sample_ms "${NETWORK_REVAMPED_MS}"
  network_revamped_store download_ts "${NETWORK_REVAMPED_NOW}"
}

network_revamped_first_match() {
  awk -v pattern="$1" 'match($0, pattern) { print substr($0, RSTART, RLENGTH); exit }'
}

network_revamped_read_vpn() {
  if revamped_is_macos; then
    network_revamped_read_vpn_raw=$(netstat -rn -f inet 2>/dev/null) || network_revamped_read_vpn_raw=""
    NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_vpn_raw}" | network_revamped_first_match '(utun|tun|tap|ipsec|ppp)[0-9]+')
    return 0
  fi
  network_revamped_read_vpn_raw=$(ip -o link show up 2>/dev/null) || network_revamped_read_vpn_raw=""
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_vpn_raw}" | awk '{ name = $2; sub(/[@:].*$/, "", name); if (name ~ /^(tun|tap|wg|ppp|nordlynx|tailscale)[0-9]*$/) { print name; exit } }')
}

network_revamped_read_vpn_name() {
  if revamped_is_macos; then
    network_revamped_read_vpn_name_raw=$(scutil --nc list 2>/dev/null) || network_revamped_read_vpn_name_raw=""
    NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_vpn_name_raw}" | awk -F '"' '/Connected/ { print $2; exit }')
    return 0
  fi
  network_revamped_read_vpn_name_raw=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null) || network_revamped_read_vpn_name_raw=""
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_vpn_name_raw}" | awk -F ':' '$2 == "vpn" || $2 == "wireguard" { print $1; exit }')
}

network_revamped_read_ip() {
  NETWORK_REVAMPED_READ=""
  [ -n "${NETWORK_REVAMPED_IFACE}" ] || return 0
  if revamped_is_macos; then
    NETWORK_REVAMPED_READ=$(ipconfig getifaddr "${NETWORK_REVAMPED_IFACE}" 2>/dev/null) || NETWORK_REVAMPED_READ=""
    return 0
  fi
  network_revamped_read_ip_raw=$(ip addr show dev "${NETWORK_REVAMPED_IFACE}" 2>/dev/null) || network_revamped_read_ip_raw=""
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_ip_raw}" | awk '$1 == "inet" { split($2, part, "/"); print part[1]; exit }')
}

network_revamped_read_connections() {
  NETWORK_REVAMPED_READ=""
  if revamped_has_command netstat; then
    network_revamped_read_connections_raw=$(netstat -an 2>/dev/null) || network_revamped_read_connections_raw=""
    NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_connections_raw}" | awk '/ESTABLISHED/ { count++ } END { print count + 0 }')
  elif revamped_has_command ss; then
    network_revamped_read_connections_raw=$(ss -Htan state established 2>/dev/null) || network_revamped_read_connections_raw=""
    NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_connections_raw}" | awk 'NF > 0 { count++ } END { print count + 0 }')
  fi
}

network_revamped_airport() {
  [ "${NETWORK_REVAMPED_AIRPORT_READ}" = 0 ] || return 0
  NETWORK_REVAMPED_AIRPORT_READ=1
  NETWORK_REVAMPED_AIRPORT=$(system_profiler SPAirPortDataType 2>/dev/null) || NETWORK_REVAMPED_AIRPORT=""
}

network_revamped_read_wifi() {
  if revamped_is_macos; then
    network_revamped_airport
    NETWORK_REVAMPED_READ=$(printf '%s\n' "${NETWORK_REVAMPED_AIRPORT}" | awk '/Signal \/ Noise/ { if (match($0, /-[0-9]+/)) { print substr($0, RSTART, RLENGTH) } exit }')
    return 0
  fi
  network_revamped_read_wifi_raw=$(cat /proc/net/wireless 2>/dev/null) || network_revamped_read_wifi_raw=""
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_wifi_raw}" | awk 'NR > 2 { gsub(/[^0-9-]/, "", $4); print $4; exit }')
}

network_revamped_read_ssid() {
  if revamped_is_macos; then
    network_revamped_airport
    NETWORK_REVAMPED_READ=$(printf '%s\n' "${NETWORK_REVAMPED_AIRPORT}" | awk '/Current Network Information:/ { getline line; sub(/^[[:space:]]+/, "", line); sub(/:[[:space:]]*$/, "", line); print line; exit }')
    return 0
  fi
  network_revamped_read_ssid_raw=$(iwgetid -r 2>/dev/null) || network_revamped_read_ssid_raw=""
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_ssid_raw}" | awk 'NR == 1 { sub(/[[:space:]]+$/, "", $0); print; exit }')
  [ -z "${NETWORK_REVAMPED_READ}" ] || return 0
  [ -n "${NETWORK_REVAMPED_IFACE}" ] || return 0
  network_revamped_read_ssid_raw=$(iw dev "${NETWORK_REVAMPED_IFACE}" link 2>/dev/null) || network_revamped_read_ssid_raw=""
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_ssid_raw}" | awk '/SSID:/ { sub(/^.*SSID:[[:space:]]*/, "", $0); print; exit }')
}

network_revamped_read_ping() {
  if revamped_is_macos; then
    network_revamped_read_ping_raw=$(ping -c 1 -t 1 "${NETWORK_REVAMPED_PING_HOST}" 2>/dev/null) || network_revamped_read_ping_raw=""
  else
    network_revamped_read_ping_raw=$(ping -c 1 -w 1 "${NETWORK_REVAMPED_PING_HOST}" 2>/dev/null) || network_revamped_read_ping_raw=""
  fi
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_ping_raw}" | awk 'match($0, /time=[0-9.]+/) { value = substr($0, RSTART + 5, RLENGTH - 5); sub(/\..*$/, "", value); print value; exit }')
}

network_revamped_read_public_ip() {
  network_revamped_read_public_ip_raw=$(curl -sf --connect-timeout 2 -m 3 "${NETWORK_REVAMPED_PUBLIC_IP_URL}" 2>/dev/null) || network_revamped_read_public_ip_raw=""
  NETWORK_REVAMPED_READ=$(printf '%s\n' "${network_revamped_read_public_ip_raw}" | awk 'NR == 1 && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ { print $1 }')
}

network_revamped_read_online() {
  NETWORK_REVAMPED_READ=""
  if revamped_has_command curl; then
    ! curl -sf -o /dev/null --connect-timeout 2 -m 3 "${NETWORK_REVAMPED_ONLINE_URL}" 2>/dev/null || NETWORK_REVAMPED_READ=up
    return 0
  fi
  network_revamped_read_ping
  [ -z "${NETWORK_REVAMPED_READ}" ] || NETWORK_REVAMPED_READ=up
}

network_revamped_due() {
  case " ${NETWORK_REVAMPED_WANT} " in
  *" $1 "*) network_revamped_number "$3" "$4" ;;
  *) return 1 ;;
  esac
  revamped_cache_is_number "$2" || return 0
  [ "$((NETWORK_REVAMPED_NOW - $2))" -gt "${NETWORK_REVAMPED_NUMBER}" ]
}

network_revamped_keep() {
  network_revamped_store "$1" "${NETWORK_REVAMPED_READ}"
  network_revamped_store "$1_ts" "${NETWORK_REVAMPED_NOW}"
}

network_revamped_probes() {
  NETWORK_REVAMPED_AIRPORT_READ=0
  if network_revamped_due vpn "${NETWORK_REVAMPED_S_vpn_ts}" "${NETWORK_REVAMPED_S_vpn_interval}" "${NETWORK_REVAMPED_DEFAULT_PROBE}"; then
    network_revamped_read_vpn
    network_revamped_keep vpn
  fi
  if network_revamped_due vpn_name "${NETWORK_REVAMPED_S_vpn_name_ts}" "${NETWORK_REVAMPED_S_vpn_name_interval}" "${NETWORK_REVAMPED_DEFAULT_PROBE}"; then
    network_revamped_read_vpn_name
    network_revamped_keep vpn_name
  fi
  if network_revamped_due ip "${NETWORK_REVAMPED_S_ip_ts}" "${NETWORK_REVAMPED_S_ip_interval}" "${NETWORK_REVAMPED_DEFAULT_PROBE}"; then
    network_revamped_read_ip
    network_revamped_keep ip
  fi
  if network_revamped_due connections "${NETWORK_REVAMPED_S_connections_ts}" "${NETWORK_REVAMPED_S_connections_interval}" "${NETWORK_REVAMPED_DEFAULT_PROBE}"; then
    network_revamped_read_connections
    network_revamped_keep connections
  fi
  if network_revamped_due wifi "${NETWORK_REVAMPED_S_wifi_ts}" "${NETWORK_REVAMPED_S_wifi_interval}" "${NETWORK_REVAMPED_DEFAULT_PROBE}"; then
    network_revamped_read_wifi
    network_revamped_keep wifi
  fi
  if network_revamped_due ssid "${NETWORK_REVAMPED_S_ssid_ts}" "${NETWORK_REVAMPED_S_ssid_interval}" "${NETWORK_REVAMPED_DEFAULT_PROBE}"; then
    network_revamped_read_ssid
    network_revamped_keep ssid
  fi
  network_revamped_probes_remote
}

network_revamped_probes_remote() {
  if [ "${NETWORK_REVAMPED_S_ping_enabled}" = 1 ] && network_revamped_due ping "${NETWORK_REVAMPED_S_ping_ts}" "${NETWORK_REVAMPED_S_ping_interval}" "${NETWORK_REVAMPED_DEFAULT_PING}"; then
    network_revamped_read_ping
    network_revamped_keep ping
  fi
  if [ "${NETWORK_REVAMPED_S_public_ip_enabled}" = 1 ] && network_revamped_due public_ip "${NETWORK_REVAMPED_S_public_ip_ts}" "${NETWORK_REVAMPED_S_public_ip_interval}" "${NETWORK_REVAMPED_DEFAULT_PUBLIC_IP}"; then
    network_revamped_read_public_ip
    network_revamped_keep public_ip
  fi
  if [ "${NETWORK_REVAMPED_S_online_enabled}" = 1 ] && network_revamped_due online "${NETWORK_REVAMPED_S_online_ts}" "${NETWORK_REVAMPED_S_online_interval}" "${NETWORK_REVAMPED_DEFAULT_PROBE}"; then
    network_revamped_read_online
    network_revamped_keep online
  fi
}

network_revamped_refresh() {
  NETWORK_REVAMPED_PLAN=""
  network_revamped_clock
  network_revamped_iface
  network_revamped_sample
  network_revamped_probes
  NETWORK_REVAMPED_STORED=1
  network_revamped_send || NETWORK_REVAMPED_STORED=0
}

network_revamped_limit() {
  network_revamped_number "${NETWORK_REVAMPED_S_interval}" "${NETWORK_REVAMPED_DEFAULT_INTERVAL}"
  NETWORK_REVAMPED_LIMIT="${NETWORK_REVAMPED_NUMBER}"
}

network_revamped_stale() {
  revamped_cache_is_number "${NETWORK_REVAMPED_S_download_ts}" || return 0
  [ "$((NETWORK_REVAMPED_NOW - NETWORK_REVAMPED_S_download_ts))" -gt "${NETWORK_REVAMPED_LIMIT}" ]
}

network_revamped_locked() {
  [ "${NETWORK_REVAMPED_S_download_lock}" = 1 ] || return 1
  revamped_cache_is_number "${NETWORK_REVAMPED_S_download_lock_ts}" || return 1
  [ "$((NETWORK_REVAMPED_NOW - NETWORK_REVAMPED_S_download_lock_ts))" -lt "${REVAMPED_CACHE_MAX_RUN_DEFAULT}" ]
}

network_revamped_tier() {
  network_revamped_number "${NETWORK_REVAMPED_S_medium_thresh}" "${NETWORK_REVAMPED_DEFAULT_MEDIUM}"
  network_revamped_tier_medium="${NETWORK_REVAMPED_NUMBER}"
  network_revamped_number "${NETWORK_REVAMPED_S_high_thresh}" "${NETWORK_REVAMPED_DEFAULT_HIGH}"
  network_revamped_tier_rate=$((NETWORK_REVAMPED_S_total / 1024))
  if [ "${network_revamped_tier_rate}" -ge "${NETWORK_REVAMPED_NUMBER}" ]; then
    NETWORK_REVAMPED_TIER=high
  elif [ "${network_revamped_tier_rate}" -ge "${network_revamped_tier_medium}" ]; then
    NETWORK_REVAMPED_TIER=medium
  else
    NETWORK_REVAMPED_TIER=low
  fi
}

network_revamped_value_colour() {
  NETWORK_REVAMPED_OUT=""
  revamped_cache_is_number "${NETWORK_REVAMPED_S_total}" || return 0
  network_revamped_tier
  case "$1:${NETWORK_REVAMPED_TIER}" in
  fg_color:high) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_high_fg_color}" ;;
  fg_color:medium) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_medium_fg_color}" ;;
  fg_color:low) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_low_fg_color}" ;;
  bg_color:high) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_high_bg_color}" ;;
  bg_color:medium) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_medium_bg_color}" ;;
  *) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_low_bg_color}" ;;
  esac
}

network_revamped_value_speed() {
  NETWORK_REVAMPED_OUT=""
  [ -n "${NETWORK_REVAMPED_S_download}${NETWORK_REVAMPED_S_upload}" ] || return 0
  # shellcheck disable=SC2059
  NETWORK_REVAMPED_OUT=$(printf "${NETWORK_REVAMPED_S_speed_format}" "${NETWORK_REVAMPED_S_download}" "${NETWORK_REVAMPED_S_upload}")
}

network_revamped_value_shaped() {
  NETWORK_REVAMPED_OUT=""
  [ -n "$2" ] || return 0
  # shellcheck disable=SC2059
  NETWORK_REVAMPED_OUT=$(printf "$1" "$2")
}

network_revamped_value_online() {
  NETWORK_REVAMPED_OUT=""
  if [ "${NETWORK_REVAMPED_S_online}" = up ]; then
    NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_online_up_text}"
  elif [ "${NETWORK_REVAMPED_S_online_enabled}" = 1 ]; then
    NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_online_down_text}"
  fi
}

network_revamped_value_outside() {
  network_revamped_doubled "$1"
  NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_DOUBLED}"
}

network_revamped_value() {
  case "$1" in
  download) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_download}" ;;
  upload) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_upload}" ;;
  speed) network_revamped_value_speed ;;
  fg_color | bg_color) network_revamped_value_colour "$1" ;;
  vpn) network_revamped_value_outside "${NETWORK_REVAMPED_S_vpn}" ;;
  vpn_name) network_revamped_value_outside "${NETWORK_REVAMPED_S_vpn_name}" ;;
  ip) network_revamped_value_outside "${NETWORK_REVAMPED_S_ip}" ;;
  wifi) network_revamped_value_shaped "${NETWORK_REVAMPED_S_wifi_format}" "${NETWORK_REVAMPED_S_wifi}" ;;
  ssid) network_revamped_value_outside "${NETWORK_REVAMPED_S_ssid}" ;;
  connections) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_connections}" ;;
  ping) network_revamped_value_shaped "${NETWORK_REVAMPED_S_ping_format}" "${NETWORK_REVAMPED_S_ping}" ;;
  public_ip) NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_S_public_ip}" ;;
  *) network_revamped_value_online ;;
  esac
}

network_revamped_own() {
  NETWORK_REVAMPED_NATURAL=0
  case "$1" in
  download)
    NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_download_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_download_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0207\0232'
    network_revamped_own_rate
    ;;
  upload)
    NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_upload_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_upload_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0225\0222'
    network_revamped_own_rate
    ;;
  speed) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_speed_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_speed_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0223\0242' ;;
  vpn) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_vpn_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_vpn_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0226\0202' ;;
  vpn_name) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_vpn_name_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_vpn_name_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0226\0202' ;;
  ip) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_ip_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_ip_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0251\0240' ;;
  wifi) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_wifi_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_wifi_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0226\0251' ;;
  ssid) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_ssid_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_ssid_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0226\0251' ;;
  connections) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_connections_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_connections_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0214\0230' ;;
  ping) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_ping_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_ping_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0200\0203' NETWORK_REVAMPED_NATURAL="${NETWORK_REVAMPED_PING_NATURAL}" ;;
  public_ip) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_public_ip_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_public_ip_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0207\0247' ;;
  *) NETWORK_REVAMPED_LABEL="${NETWORK_REVAMPED_S_online_label}" NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_S_online_width}" NETWORK_REVAMPED_GLYPH='\0363\0260\0226\0237' ;;
  esac
}

network_revamped_own_rate() {
  network_revamped_precision
  NETWORK_REVAMPED_NATURAL=$((NETWORK_REVAMPED_RATE_NATURAL + NETWORK_REVAMPED_PLACES))
  [ "${NETWORK_REVAMPED_PLACES}" -gt 0 ] || NETWORK_REVAMPED_NATURAL=$((NETWORK_REVAMPED_RATE_NATURAL - 1))
}

network_revamped_pad() {
  if ! revamped_cache_is_number "${NETWORK_REVAMPED_WIDTH}"; then
    NETWORK_REVAMPED_WIDTH=0
    [ "${NETWORK_REVAMPED_S_fixed_width}" != on ] || NETWORK_REVAMPED_WIDTH="${NETWORK_REVAMPED_NATURAL}"
  fi
  [ "${NETWORK_REVAMPED_WIDTH}" -gt 0 ] || return 0
  revamped_publish_count "${NETWORK_REVAMPED_OUT}"
  [ "${revamped_publish_count_out}" -lt "${NETWORK_REVAMPED_WIDTH}" ] || return 0
  network_revamped_pad_gap=$(printf "%$((NETWORK_REVAMPED_WIDTH - revamped_publish_count_out))s" '')
  NETWORK_REVAMPED_OUT="${network_revamped_pad_gap}${NETWORK_REVAMPED_OUT}"
}

network_revamped_label() {
  [ -z "${NETWORK_REVAMPED_LABEL}" ] || return 0
  [ "${NETWORK_REVAMPED_S_icons}" = nerd ] || return 0
  NETWORK_REVAMPED_LABEL=$(printf '%b' "${NETWORK_REVAMPED_GLYPH}")
}

network_revamped_output() {
  network_revamped_value "$1"
  [ -n "${NETWORK_REVAMPED_OUT}" ] || return 0
  case "$1" in
  fg_color | bg_color) return 0 ;;
  *) network_revamped_own "$1" ;;
  esac
  network_revamped_pad
  network_revamped_label "$1"
  [ -z "${NETWORK_REVAMPED_LABEL}" ] || NETWORK_REVAMPED_OUT="${NETWORK_REVAMPED_LABEL} ${NETWORK_REVAMPED_OUT}"
}

network_revamped_show() {
  network_revamped_output "$1"
  [ -z "${NETWORK_REVAMPED_OUT}" ] || printf '%s\n' "${NETWORK_REVAMPED_OUT}"
}

network_revamped_status() {
  network_revamped_load
  network_revamped_now
  network_revamped_limit
  NETWORK_REVAMPED_WANT="${NETWORK_REVAMPED_S_published} $1"
  if network_revamped_stale && ! network_revamped_locked; then
    revamped_cache_refresh_if_stale download "${NETWORK_REVAMPED_LIMIT}" network_revamped_refresh || :
  fi
  network_revamped_show "$1"
}

network_revamped_publish() {
  NETWORK_REVAMPED_WANT="${NETWORK_REVAMPED_S_published}"
  network_revamped_refresh
  [ "${NETWORK_REVAMPED_STORED}" = 1 ] || return 0
  network_revamped_publish_rest="${NETWORK_REVAMPED_S_published}"
  while [ -n "${network_revamped_publish_rest}" ]; do
    network_revamped_publish_metric="${network_revamped_publish_rest%% *}"
    network_revamped_publish_rest="${network_revamped_publish_rest#"${network_revamped_publish_metric}"}"
    network_revamped_publish_rest="${network_revamped_publish_rest# }"
    [ -n "${network_revamped_publish_metric}" ] || continue
    network_revamped_output "${network_revamped_publish_metric}"
    revamped_publish_add "@net_revamped_out_${network_revamped_publish_metric}" "${NETWORK_REVAMPED_OUT}"
  done
  revamped_publish_commit || :
}

network_revamped_tick() {
  network_revamped_load
  network_revamped_publish
}

network_revamped_daemon() {
  revamped_ticker_run net_revamped network_revamped_tick "$$" "${NETWORK_REVAMPED_DEFAULT_INTERVAL}"
}

network_revamped_popup() {
  network_revamped_version
  if ! network_revamped_version_ge "${NETWORK_REVAMPED_TMUX}" "${NETWORK_REVAMPED_POPUP_SINCE}"; then
    network_revamped_say "the popup needs tmux ${NETWORK_REVAMPED_POPUP_SINCE} or later"
    return 0
  fi
  network_revamped_tools
  tmux display-popup -E -w "${NETWORK_REVAMPED_POPUP_WIDTH}" -h "${NETWORK_REVAMPED_POPUP_HEIGHT}" "${NETWORK_REVAMPED_TOOL} card; printf '\\nPress Enter to close. '; read -r network_revamped_wait" 2>/dev/null || :
}

network_revamped_plan_keys() {
  case "${NETWORK_REVAMPED_S_popup_key}: ${NETWORK_REVAMPED_KEYS} " in
  "${NETWORK_REVAMPED_DEFAULT_POPUP_KEY}:"*" ${NETWORK_REVAMPED_DEFAULT_POPUP_KEY} "*) NETWORK_REVAMPED_SKIPPED="${NETWORK_REVAMPED_SKIPPED}${NETWORK_REVAMPED_SKIPPED:+ }${NETWORK_REVAMPED_DEFAULT_POPUP_KEY}" ;;
  *) network_revamped_bind "${NETWORK_REVAMPED_S_popup_key}" "Network details" run-shell "${NETWORK_REVAMPED_TOOL} popup" ;;
  esac
}

network_revamped_replaced() {
  printf '%s\n' "$1" | NETWORK_REVAMPED_PUT="${NETWORK_REVAMPED_JOB}" awk -v mode="${NETWORK_REVAMPED_S_render}" -v kinds="${NETWORK_REVAMPED_METRICS}" '
    BEGIN {
      command = ENVIRON["NETWORK_REVAMPED_PUT"]
      count = split(kinds, kind, " ")
    }
    {
      line = $0
      for (i = 1; i <= count; i++) {
        holder = "#{net_" kind[i] "}"
        target = (mode == "options") ? "#{E:@net_revamped_out_" kind[i] "}" : "#(" command " status " kind[i] ")"
        done = ""
        while ((at = index(line, holder)) > 0) {
          done = done substr(line, 1, at - 1) target
          line = substr(line, at + length(holder))
        }
        line = done line
      }
      print line
    }
  '
}

network_revamped_used() {
  printf '%s\n' "$1" | awk -v kinds="${NETWORK_REVAMPED_METRICS}" '
    BEGIN { count = split(kinds, kind, " ") }
    { text = text $0 " " }
    END {
      out = ""
      for (i = 1; i <= count; i++) {
        if (index(text, "#{net_" kind[i] "}") > 0 || index(text, "@net_revamped_out_" kind[i] "}") > 0 || index(text, " status " kind[i] ")") > 0) { out = out (out == "" ? "" : " ") kind[i] }
      }
      print out
    }
  '
}

network_revamped_plan_status() {
  network_revamped_plan_status_all=""
  for network_revamped_plan_status_option in status-left status-right; do
    network_revamped_plan_status_now=$(tmux show-option -gqv "${network_revamped_plan_status_option}" 2>/dev/null) || network_revamped_plan_status_now=""
    network_revamped_plan_status_all="${network_revamped_plan_status_all} ${network_revamped_plan_status_now}"
    case "${network_revamped_plan_status_now}" in
    *"#{net_"*"}"*) network_revamped_plan_status_new=$(network_revamped_replaced "${network_revamped_plan_status_now}") ;;
    *) continue ;;
    esac
    [ "${network_revamped_plan_status_new}" != "${network_revamped_plan_status_now}" ] || continue
    network_revamped_emit set-option -gq "${network_revamped_plan_status_option}" "${network_revamped_plan_status_new}"
  done
  network_revamped_plan_status_used=$(network_revamped_used "${network_revamped_plan_status_all}")
  [ "${network_revamped_plan_status_used}" = "${NETWORK_REVAMPED_S_published}" ] || network_revamped_emit set-option -gq @net_revamped_published "${network_revamped_plan_status_used}"
  NETWORK_REVAMPED_S_published="${network_revamped_plan_status_used}"
}

network_revamped_plan() {
  network_revamped_load
  network_revamped_version
  NETWORK_REVAMPED_NOTES=0
  ! network_revamped_version_ge "${NETWORK_REVAMPED_TMUX}" "${NETWORK_REVAMPED_NOTES_SINCE}" || NETWORK_REVAMPED_NOTES=1
  network_revamped_tools
  NETWORK_REVAMPED_KEYS=$(network_revamped_held)
  NETWORK_REVAMPED_PLAN="" NETWORK_REVAMPED_SKIPPED=""
  network_revamped_plan_keys
  network_revamped_plan_status
}

network_revamped_apply() {
  network_revamped_plan
  network_revamped_apply_status=0
  network_revamped_deliver || network_revamped_apply_status=1
  if [ "${NETWORK_REVAMPED_S_render}" = options ]; then
    revamped_ticker_start "${REVAMPED_LIB%/lib}/bin/network-revamped"
  else
    tmux set-option -gqu @net_revamped_ticker_pid 2>/dev/null || :
  fi
  return "${network_revamped_apply_status}"
}
