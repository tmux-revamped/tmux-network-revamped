#!/usr/bin/env bash
#
# network.sh: command dispatcher for tmux-network-revamped.
#
# Usage: network.sh download | upload | speed | fg_color | bg_color | refresh
#
# The worker reads interface counters, computes the rate against the previous
# counters held in tmux options, then stores the new counters for next time.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="net_revamped"
export PLUGIN_LOG_NS="network-revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/platform.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/publish.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/ticker.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/network/network.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/network/render.sh"

network_max_age() {
  get_tmux_option "@net_revamped_interval" "2"
}

# net_probe_max_age PROBE DEFAULT -> the per-probe refresh interval in seconds.
# Heavy probes share the speed worker but read their own interval option so each
# refreshes on a longer schedule than the fast speed sample.
net_probe_max_age() {
  get_tmux_option "@net_revamped_${1}_interval" "${2}"
}

net_interface() {
  local i
  i=$(get_tmux_option "@net_revamped_interface" "")
  [[ -n "${i}" ]] && { echo "${i}"; return 0; }
  default_iface
}

network_refresh() {
  local iface rx tx now prev_rx prev_tx prev_ts dt down up
  iface=$(net_interface)
  read -r rx tx <<< "$(read_counters "${iface}")"
  [[ "${rx}" =~ ^[0-9]+$ ]] || return 0

  now=$(net_now_ms)
  prev_rx=$(cache_get rx_raw)
  prev_tx=$(cache_get tx_raw)
  prev_ts=$(cache_get sample_ms)

  if [[ "${prev_ts}" =~ ^[0-9]+$ ]]; then
    dt=$(( now - prev_ts ))
    down=$(net_rate_compute_ms "${rx}" "${prev_rx}" "${dt}")
    up=$(net_rate_compute_ms "${tx}" "${prev_tx}" "${dt}")
  else
    down=0
    up=0
  fi

  local weight
  weight="$(get_tmux_option "@net_revamped_smoothing" "0")"
  down=$(net_smooth "${down}" "$(cache_get down_smooth)" "${weight}")
  up=$(net_smooth "${up}" "$(cache_get up_smooth)" "${weight}")
  cache_set down_smooth "${down}"
  cache_set up_smooth "${up}"

  local precision
  precision="$(get_tmux_option "@net_revamped_precision" "1")"
  cache_set download "$(net_format_rate "${down}" "${precision}")"
  cache_set upload "$(net_format_rate "${up}" "${precision}")"
  cache_set total "$(( down + up ))"
  cache_set rx_raw "${rx}"
  cache_set tx_raw "${tx}"
  cache_set sample_ms "${now}"

  cache_set_if_stale vpn "$(net_probe_max_age vpn 30)" read_vpn
  cache_set_if_stale connections "$(net_probe_max_age connections 30)" read_connections
  cache_set_if_stale wifi "$(net_probe_max_age wifi 30)" read_wifi
  cache_set_if_stale ssid "$(net_probe_max_age ssid 30)" read_ssid
  cache_set_if_stale ip "$(net_probe_max_age ip 30)" read_lan_ip
  cache_set_if_stale vpn_name "$(net_probe_max_age vpn_name 30)" read_vpn_name
  if [[ "$(get_tmux_option "@net_revamped_ping_enabled" "0")" == "1" ]]; then
    cache_set_if_stale ping "$(net_probe_max_age ping 15)" read_ping
  fi
  if [[ "$(get_tmux_option "@net_revamped_public_ip_enabled" "0")" == "1" ]]; then
    cache_set_if_stale public_ip "$(net_probe_max_age public_ip 300)" read_public_ip
  fi
  if [[ "$(get_tmux_option "@net_revamped_online_enabled" "0")" == "1" ]]; then
    cache_set_if_stale online "$(net_probe_max_age online 30)" read_online
  fi
  return 0
}

network_tick() {
  cache_refresh_if_stale download "$(network_max_age)" network_refresh
}

network_render_metric() {
  local cmd="${1}"
  case "${cmd}" in
    download) net_render_text "$(cache_get download)" ;;
    upload)   net_render_text "$(cache_get upload)" ;;
    speed)    net_render_speed "$(cache_get download)" "$(cache_get upload)" ;;
    fg_color) net_render_fg "$(cache_get total)" ;;
    bg_color) net_render_bg "$(cache_get total)" ;;
    vpn)      net_render_text "$(cache_get vpn)" ;;
    vpn_name) net_render_text "$(cache_get vpn_name)" ;;
    ip)       net_render_text "$(cache_get ip)" ;;
    wifi)     net_render_wifi "$(cache_get wifi)" ;;
    ssid)     net_render_text "$(cache_get ssid)" ;;
    connections) net_render_text "$(cache_get connections)" ;;
    ping)     net_render_ping "$(cache_get ping)" ;;
    public_ip) net_render_text "$(cache_get public_ip)" ;;
    online)   net_render_online "$(cache_get online)" ;;
    *)        return 0 ;;
  esac
}

network_is_labelled() {
  case "${1}" in
    download | upload | speed | vpn | vpn_name | ip | wifi | ssid | connections | ping | public_ip | online) return 0 ;;
    *) return 1 ;;
  esac
}

network_nerd_label() {
  case "${1}" in
    download) printf '\xf3\xb0\x87\x9a' ;;
    upload) printf '\xf3\xb0\x95\x92' ;;
    speed) printf '\xf3\xb0\x93\xa2' ;;
    vpn) printf '\xf3\xb0\x96\x82' ;;
    vpn_name) printf '\xf3\xb0\x96\x82' ;;
    ip) printf '\xf3\xb0\xa9\xa0' ;;
    wifi) printf '\xf3\xb0\x96\xa9' ;;
    ssid) printf '\xf3\xb0\x96\xa9' ;;
    connections) printf '\xf3\xb0\x8c\x98' ;;
    ping) printf '\xf3\xb0\x80\x83' ;;
    public_ip) printf '\xf3\xb0\x87\xa7' ;;
    online) printf '\xf3\xb0\x96\x9f' ;;
    *) printf '' ;;
  esac
}

network_option_exists() {
  [[ -n "$(tmux show-option -gq "${1}" 2>/dev/null)" ]]
}

network_label() {
  local option="@net_revamped_${1}_label"
  if network_option_exists "${option}"; then
    tmux show-option -gqv "${option}" 2>/dev/null
  elif [[ "$(get_tmux_option "@net_revamped_icons" "ascii")" == "nerd" ]]; then
    network_nerd_label "${1}"
  fi
}

network_natural_width() {
  local precision
  case "${1}" in
    download | upload)
      precision="$(get_tmux_option "@net_revamped_precision" "1")"
      [[ "${precision}" =~ ^[0-9]+$ ]] || precision=1
      if (( precision > 0 )); then
        printf '%s' "$(( 8 + precision ))"
      else
        printf '7'
      fi
      ;;
    ping) printf '5' ;;
    *) printf '0' ;;
  esac
}

network_padded() {
  publish_pad "${2}" "$(publish_width net_revamped "${1}" "$(network_natural_width "${1}")")"
}

network_labelled() {
  local metric="${1}" value="${2}" label
  [[ -n "${value}" ]] || return 0
  value="$(network_padded "${metric}" "${value}")"
  label="$(network_label "${metric}")"
  if [[ -n "${label}" ]]; then
    printf '%s %s\n' "${label}" "${value}"
  else
    printf '%s\n' "${value}"
  fi
}

network_output() {
  local metric="${1}" out
  out="$(network_render_metric "${metric}")"
  if network_is_labelled "${metric}"; then
    network_labelled "${metric}" "${out}"
  elif [[ -n "${out}" ]]; then
    printf '%s\n' "${out}"
  fi
}

network_publish() {
  local metric
  network_refresh
  for metric in $(get_tmux_option "@net_revamped_published" ""); do
    publish_add "@net_revamped_out_${metric}" "$(network_output "${metric}")"
  done
  publish_commit
}

_network_reexec() { exec "${PLUGIN_DIR}/src/network.sh" daemon; }

network_daemon() {
  if ticker_run net_revamped network_publish "$$" 2; then
    _network_reexec
  fi
}

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    refresh) network_refresh; return 0 ;;
    start)   ticker_start "${PLUGIN_DIR}/src/network.sh"; return 0 ;;
    daemon)  network_daemon; return 0 ;;
  esac

  network_tick
  network_output "${cmd}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
