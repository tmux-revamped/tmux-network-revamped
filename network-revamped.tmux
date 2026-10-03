#!/usr/bin/env bash
#
# network-revamped.tmux: TPM entry point.
#
# Replaces the #{net_*} placeholders in status-left and status-right with calls
# to the dispatcher, which reads cached values and never blocks the render.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NET_CMD="${PLUGIN_DIR}/src/network.sh"

placeholders=(
  "\#{net_download}"
  "\#{net_upload}"
  "\#{net_speed}"
  "\#{net_fg_color}"
  "\#{net_bg_color}"
  "\#{net_vpn_name}"
  "\#{net_vpn}"
  "\#{net_ip}"
  "\#{net_connections}"
  "\#{net_ping}"
  "\#{net_public_ip}"
  "\#{net_wifi}"
  "\#{net_ssid}"
  "\#{net_online}"
)

commands=(
  "#(${NET_CMD} download)"
  "#(${NET_CMD} upload)"
  "#(${NET_CMD} speed)"
  "#(${NET_CMD} fg_color)"
  "#(${NET_CMD} bg_color)"
  "#(${NET_CMD} vpn_name)"
  "#(${NET_CMD} vpn)"
  "#(${NET_CMD} ip)"
  "#(${NET_CMD} connections)"
  "#(${NET_CMD} ping)"
  "#(${NET_CMD} public_ip)"
  "#(${NET_CMD} wifi)"
  "#(${NET_CMD} ssid)"
  "#(${NET_CMD} online)"
)

render_mode="$(tmux show-option -gqv "@net_revamped_render")"

target_for() {
  local command="${1}" metric
  metric="${command##* }"
  metric="${metric%)}"
  if [[ "${render_mode}" == "options" ]]; then
    printf '#{E:@net_revamped_out_%s}' "${metric}"
  else
    printf '%s' "${command}"
  fi
}

interpolate() {
  local value="${1}"
  local i
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/$(target_for "${commands[i]}")}"
  done
  echo "${value}"
}

used_metrics() {
  local text="${1}" used="" i metric
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    metric="${commands[i]##* }"
    metric="${metric%)}"
    if [[ "${text}" == *${placeholders[i]}* || "${text}" == *"@net_revamped_out_${metric}}"* ]]; then
      used="${used:+${used} }${metric}"
    fi
  done
  echo "${used}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${NET_CMD}" 2>/dev/null || true

status_text="$(tmux show-option -gqv status-left) $(tmux show-option -gqv status-right)"
tmux set-option -gq "@net_revamped_published" "$(used_metrics "${status_text}")"

update_option "status-left"
update_option "status-right"

if [[ "${render_mode}" == "options" ]]; then
  "${NET_CMD}" start 2>/dev/null || true
fi
