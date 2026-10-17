#!/usr/bin/env bash

[[ -n "${_NETWORK_REVAMPED_NETWORK_LOADED:-}" ]] && return 0
_NETWORK_REVAMPED_NETWORK_LOADED=1

_NET_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_NET_LIB_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_NET_LIB_DIR}/../utils/publish.sh"

net_counters_from_proc() {
  local line
  line=$(printf '%s\n' "${1}" | grep -E "^[[:space:]]*${2}:")
  [[ -n "${line}" ]] || { echo ""; return 0; }
  line="${line#*:}"
  local -a f
  read -ra f <<< "${line}"
  local rx="${f[0]}" tx="${f[8]}"
  [[ "${rx}" =~ ^[0-9]+$ && "${tx}" =~ ^[0-9]+$ ]] || { echo ""; return 0; }
  echo "${rx} ${tx}"
}

net_counters_from_netstat() {
  printf '%s\n' "${1}" | awk -v i="${2}" '$1 == i && NF >= 10 && $(NF-4) ~ /^[0-9]+$/ && $(NF-1) ~ /^[0-9]+$/ { print $(NF-4)" "$(NF-1); exit }'
}

net_rate_compute() {
  [[ "${1}" =~ ^[0-9]+$ && "${2}" =~ ^[0-9]+$ && "${3}" =~ ^[0-9]+$ ]] || { echo 0; return 0; }
  (( ${3} <= 0 )) && { echo 0; return 0; }
  local d=$(( ${1} - ${2} ))
  (( d < 0 )) && d=0
  echo $(( d / ${3} ))
}

net_rate_compute_ms() {
  [[ "${1}" =~ ^[0-9]+$ && "${2}" =~ ^[0-9]+$ && "${3}" =~ ^[0-9]+$ ]] || { echo 0; return 0; }
  (( ${3} <= 0 )) && { echo 0; return 0; }
  local d=$(( ${1} - ${2} ))
  (( d < 0 )) && d=0
  echo $(( d * 1000 / ${3} ))
}

net_smooth() {
  local current="${1}" previous="${2}" weight="${3}"
  [[ "${current}" =~ ^[0-9]+$ ]] || { echo 0; return 0; }
  [[ "${weight}" =~ ^[0-9]+$ ]] && (( weight > 0 && weight < 100 )) || { echo "${current}"; return 0; }
  [[ "${previous}" =~ ^[0-9]+$ ]] || { echo "${current}"; return 0; }
  echo $(( (previous * weight + current * (100 - weight)) / 100 ))
}

net_now_ms() {
  local real="${EPOCHREALTIME:-}"
  if [[ "${real}" =~ ^([0-9]+)[.,]([0-9]{3}) ]]; then
    printf '%s%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  else
    printf '%s000\n' "$(date +%s)"
  fi
}

net_format_rate() {
  local precision="${2:-1}"
  [[ "${precision}" =~ ^[0-9]$ ]] || precision=1
  [[ "${1}" =~ ^[0-9]+$ ]] || { echo "0B/s"; return 0; }
  LC_ALL=C awk -v b="${1}" -v p="${precision}" 'BEGIN {
    split("B KB MB GB TB", unit, " ");
    v = b; u = 1;
    while (u < 5) {
      r = (u == 1) ? int(v + 0.5) : sprintf("%." p "f", v) + 0;
      if (r < 1000) break;
      v = v / 1024; u++;
    }
    if (u == 1) printf "%dB/s", int(v + 0.5);
    else printf "%." p "f%s/s", v, unit[u];
  }'
}

ping_ms_from_output() {
  printf '%s\n' "${1}" | grep -m1 'time=' | sed -E 's/.*time=([0-9.]+).*/\1/' | cut -d. -f1
}

count_established() {
  printf '%s\n' "${1}" | grep -c 'ESTABLISHED'
}

valid_ipv4() {
  local ip="${1%%[[:space:]]*}"
  [[ "${ip}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "${ip}"
}

online_from_probe() {
  case "${1}" in
    0|2[0-9][0-9]|3[0-9][0-9]) echo "up" ;;
    *)                         echo "" ;;
  esac
}

vpn_from_links_linux() {
  printf '%s\n' "${1}" | grep -oE '(tun|tap|wg|ppp|nordlynx|tailscale)[0-9]*' | head -1
}

vpn_from_routes_macos() {
  printf '%s\n' "${1}" | grep -oE '(utun|tun|tap|ipsec|ppp)[0-9]+' | head -1
}

wifi_from_sp_macos() {
  printf '%s\n' "${1}" | grep -m1 'Signal / Noise' | grep -oE -- '-[0-9]+' | head -1
}

wifi_from_proc_wireless() {
  printf '%s\n' "${1}" | awk 'NR>2 { gsub(/[^0-9-]/, "", $4); print $4; exit }'
}

ssid_from_sp_macos() {
  printf '%s\n' "${1}" | awk '/Current Network Information:/ { getline line; sub(/^[[:space:]]+/, "", line); sub(/:[[:space:]]*$/, "", line); print line; exit }'
}

ssid_from_iwgetid() {
  printf '%s\n' "${1}" | awk 'NR==1 { sub(/[[:space:]]+$/, "", $0); print; exit }'
}

ssid_from_iw_link() {
  printf '%s\n' "${1}" | awk '/SSID:/ { sub(/^.*SSID:[[:space:]]*/, "", $0); print; exit }'
}

ipv4_from_ip_addr() {
  printf '%s\n' "${1}" | awk '$1 == "inet" { split($2, a, "/"); print a[1]; exit }'
}

vpn_name_from_scutil() {
  printf '%s\n' "${1}" | awk -F'"' '/Connected/ { print $2; exit }'
}

vpn_name_from_nmcli() {
  printf '%s\n' "${1}" | awk -F: '$2 == "vpn" || $2 == "wireguard" { print $1; exit }'
}

_read_proc_net_dev() { cat /proc/net/dev 2>/dev/null; }
_read_ping_linux() { ping -c 1 -w 1 8.8.8.8 2>/dev/null; }
_read_ping_macos() { ping -c 1 -t 1 8.8.8.8 2>/dev/null; }
_read_netstat_an() { netstat -an 2>/dev/null; }
_read_public_ip() { curl -sf --connect-timeout 2 -m 3 https://icanhazip.com 2>/dev/null; }
_read_curl_status() {
  curl -sf -o /dev/null --connect-timeout 2 -m 3 \
    https://www.gstatic.com/generate_204 2>/dev/null
  echo "$?"
}
_read_ip_links() { ip -o link show up 2>/dev/null; }
_read_route_table() { netstat -rn -f inet 2>/dev/null; }
_read_sp_airport() { system_profiler SPAirPortDataType 2>/dev/null; }
_read_proc_wireless() { cat /proc/net/wireless 2>/dev/null; }
_read_iwgetid() { iwgetid -r 2>/dev/null; }
# shellcheck disable=SC2120
_read_iw_dev_link() { iw dev "${1}" link 2>/dev/null; }
# shellcheck disable=SC2120
_read_ifaddr_macos() { ipconfig getifaddr "${1}" 2>/dev/null; }
# shellcheck disable=SC2120
_read_ip_addr_linux() { ip addr show dev "${1}" 2>/dev/null; }
_read_scutil_macos() { scutil --nc list 2>/dev/null; }
_read_nmcli_active_linux() { nmcli -t -f NAME,TYPE connection show --active 2>/dev/null; }

read_wifi() {
  if is_macos; then
    wifi_from_sp_macos "$(_read_sp_airport)"
  elif is_linux; then
    wifi_from_proc_wireless "$(_read_proc_wireless)"
  fi
}

read_ssid() {
  publish_escape "$(_read_ssid_raw)"
}

_read_ssid_raw() {
  if is_macos; then
    ssid_from_sp_macos "$(_read_sp_airport)"
  elif is_linux; then
    local s
    s=$(ssid_from_iwgetid "$(_read_iwgetid)")
    [[ -n "${s}" ]] && { echo "${s}"; return 0; }
    ssid_from_iw_link "$(_read_iw_dev_link "$(default_iface)")"
  fi
}

read_ping() {
  if is_linux; then
    ping_ms_from_output "$(_read_ping_linux)"
  elif is_macos; then
    ping_ms_from_output "$(_read_ping_macos)"
  fi
}

read_connections() {
  count_established "$(_read_netstat_an)"
}

read_public_ip() {
  valid_ipv4 "$(_read_public_ip)"
}

read_online() {
  if command -v curl >/dev/null 2>&1; then
    online_from_probe "$(_read_curl_status)"
  else
    local p
    p=$(read_ping)
    [[ -n "${p}" ]] && echo "up"
  fi
}

read_vpn() {
  publish_escape "$(_read_vpn_raw)"
}

_read_vpn_raw() {
  if is_macos; then
    vpn_from_routes_macos "$(_read_route_table)"
  elif is_linux; then
    vpn_from_links_linux "$(_read_ip_links)"
  fi
}

read_lan_ip() {
  publish_escape "$(_read_lan_ip_raw)"
}

_read_lan_ip_raw() {
  local iface
  iface=$(default_iface)
  [[ -n "${iface}" ]] || { echo ""; return 0; }
  if is_macos; then
    _read_ifaddr_macos "${iface}"
  elif is_linux; then
    ipv4_from_ip_addr "$(_read_ip_addr_linux "${iface}")"
  fi
}

read_vpn_name() {
  publish_escape "$(_read_vpn_name_raw)"
}

_read_vpn_name_raw() {
  if is_macos; then
    vpn_name_from_scutil "$(_read_scutil_macos)"
  elif is_linux; then
    vpn_name_from_nmcli "$(_read_nmcli_active_linux)"
  fi
}
_read_netstat() { netstat -ib 2>/dev/null; }
_default_iface_linux() { ip route show default 2>/dev/null | awk '/default/ { print $5; exit }'; }
_default_iface_macos() { route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }'; }

default_iface() {
  if is_linux; then
    _default_iface_linux
  elif is_macos; then
    _default_iface_macos
  fi
}

read_counters() {
  local iface="${1}"
  [[ -n "${iface}" ]] || { echo ""; return 0; }
  if is_linux; then
    net_counters_from_proc "$(_read_proc_net_dev)" "${iface}"
  elif is_macos; then
    net_counters_from_netstat "$(_read_netstat)" "${iface}"
  else
    echo ""
  fi
}

export -f net_counters_from_proc
export -f net_counters_from_netstat
export -f net_rate_compute
export -f net_rate_compute_ms
export -f net_now_ms
export -f net_smooth
export -f net_format_rate
export -f _read_proc_net_dev
export -f _read_netstat
export -f _default_iface_linux
export -f _default_iface_macos
export -f ping_ms_from_output
export -f count_established
export -f valid_ipv4
export -f online_from_probe
export -f vpn_from_links_linux
export -f vpn_from_routes_macos
export -f wifi_from_sp_macos
export -f wifi_from_proc_wireless
export -f ssid_from_sp_macos
export -f ssid_from_iwgetid
export -f ssid_from_iw_link
export -f ipv4_from_ip_addr
export -f vpn_name_from_scutil
export -f vpn_name_from_nmcli
export -f _read_ifaddr_macos
export -f _read_ip_addr_linux
export -f _read_scutil_macos
export -f _read_nmcli_active_linux
export -f _read_ping_linux
export -f _read_ping_macos
export -f _read_netstat_an
export -f _read_public_ip
export -f _read_curl_status
export -f _read_ip_links
export -f _read_route_table
export -f _read_sp_airport
export -f _read_proc_wireless
export -f _read_iwgetid
export -f _read_iw_dev_link
export -f default_iface
export -f read_counters
export -f read_ping
export -f read_connections
export -f read_public_ip
export -f read_online
export -f read_vpn
export -f read_lan_ip
export -f read_vpn_name
export -f _read_vpn_name_raw
export -f _read_vpn_raw
export -f _read_lan_ip_raw
export -f _read_ssid_raw
export -f read_wifi
export -f read_ssid
