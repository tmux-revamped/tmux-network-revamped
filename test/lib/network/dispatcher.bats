#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _NETWORK_REVAMPED_NETWORK_LOADED _NETWORK_REVAMPED_RENDER_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/network.sh"
  default_iface() { echo "eth0"; }
  NET_RX=1000
  NET_TX=2000
  read_counters() { echo "${NET_RX} ${NET_TX}"; }
  read_vpn() { echo "wg0"; }
  read_connections() { echo "12"; }
  read_ping() { echo "9"; }
  read_public_ip() { echo "198.51.100.9"; }
  read_wifi() { echo "-55"; }
  read_ssid() { echo "HomeWiFi"; }
  read_lan_ip() { echo "192.168.1.42"; }
  read_vpn_name() { echo "Work VPN"; }
  read_online() { echo "up"; }
}

teardown() {
  cleanup_test_environment
}

@test "network.sh dispatcher - functions are defined" {
  function_exists main
  function_exists network_refresh
  function_exists network_tick
  function_exists network_max_age
  function_exists net_interface
  function_exists net_probe_max_age
}

@test "network.sh dispatcher - network_max_age default is 2" {
  [[ "$(network_max_age)" == "2" ]]
}

@test "network.sh dispatcher - net_interface honors the option" {
  set_tmux_option "@net_revamped_interface" "wlan0"
  [[ "$(net_interface)" == "wlan0" ]]
}

@test "network.sh dispatcher - net_interface auto-detects by default" {
  [[ "$(net_interface)" == "eth0" ]]
}

@test "network.sh dispatcher - first sample reports zero and stores counters" {
  unset EPOCHREALTIME
  export MOCK_EPOCH=1000
  network_refresh
  [[ "$(cache_get download)" == "0B/s" ]]
  [[ "$(cache_get rx_raw)" == "1000" ]]
  [[ "$(cache_get sample_ms)" == "1000000" ]]
}

@test "network.sh dispatcher - second sample computes the rate" {
  unset EPOCHREALTIME
  export MOCK_EPOCH=1000
  network_refresh
  NET_RX=3048
  NET_TX=2000
  export MOCK_EPOCH=1002
  network_refresh
  [[ "$(cache_get download)" == "1.0KB/s" ]]
  [[ "$(cache_get upload)" == "0B/s" ]]
}

@test "network.sh dispatcher - refresh keeps the last value when unreadable" {
  cache_set download "9.9MB/s"
  read_counters() { echo ""; }
  network_refresh
  [[ "$(cache_get download)" == "9.9MB/s" ]]
}

@test "network.sh dispatcher - download renders the cached value" {
  export MOCK_EPOCH=1000
  run main download
  [[ "${output}" == "0B/s" ]]
}

@test "network.sh dispatcher - speed joins download and upload" {
  export MOCK_EPOCH=1000
  main refresh
  run main speed
  [[ "${output}" == "0B/s 0B/s" ]]
}

@test "network.sh dispatcher - refresh caches vpn, connections, wifi" {
  export MOCK_EPOCH=1000
  network_refresh
  [[ "$(cache_get vpn)" == "wg0" ]]
  [[ "$(cache_get connections)" == "12" ]]
  [[ "$(cache_get wifi)" == "-55" ]]
}

@test "network.sh dispatcher - refresh caches ip and vpn_name" {
  export MOCK_EPOCH=1000
  network_refresh
  [[ "$(cache_get ip)" == "192.168.1.42" ]]
  [[ "$(cache_get vpn_name)" == "Work VPN" ]]
}

@test "network.sh dispatcher - ip and vpn_name subcommands render" {
  cache_set ip "192.168.1.42"
  cache_set vpn_name "Work VPN"
  run main ip
  [[ "${output}" == "192.168.1.42" ]]
  run main vpn_name
  [[ "${output}" == "Work VPN" ]]
}

@test "network.sh dispatcher - wifi subcommand renders the cache" {
  cache_set wifi "-55"
  run main wifi
  [[ "${output}" == "-55dBm" ]]
}

@test "network.sh dispatcher - ping and public_ip are opt-in" {
  export MOCK_EPOCH=1000
  network_refresh
  [[ -z "$(cache_get ping)" ]]
  set_tmux_option "@net_revamped_ping_enabled" "1"
  set_tmux_option "@net_revamped_public_ip_enabled" "1"
  network_refresh
  [[ "$(cache_get ping)" == "9" ]]
  [[ "$(cache_get public_ip)" == "198.51.100.9" ]]
}

@test "network.sh dispatcher - vpn, connections, ping subcommands render" {
  cache_set vpn "wg0"
  cache_set connections "12"
  cache_set ping "9"
  run main vpn
  [[ "${output}" == "wg0" ]]
  run main connections
  [[ "${output}" == "12" ]]
  run main ping
  [[ "${output}" == "9ms" ]]
  cache_set public_ip "198.51.100.9"
  run main public_ip
  [[ "${output}" == "198.51.100.9" ]]
}

@test "network.sh dispatcher - online is opt-in and renders the cache" {
  export MOCK_EPOCH=1000
  network_refresh
  [[ -z "$(cache_get online)" ]]
  set_tmux_option "@net_revamped_online_enabled" "1"
  network_refresh
  [[ "$(cache_get online)" == "up" ]]
  run main online
  [[ "${output}" == "on" ]]
}

@test "network.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

@test "network.sh dispatcher - net_probe_max_age default and option" {
  [[ "$(net_probe_max_age ping 15)" == "15" ]]
  set_tmux_option "@net_revamped_ping_interval" "42"
  [[ "$(net_probe_max_age ping 15)" == "42" ]]
}

@test "network.sh dispatcher - refresh caches ssid" {
  export MOCK_EPOCH=1000
  network_refresh
  [[ "$(cache_get ssid)" == "HomeWiFi" ]]
}

@test "network.sh dispatcher - ssid subcommand renders the cache" {
  cache_set ssid "HomeWiFi"
  run main ssid
  [[ "${output}" == "HomeWiFi" ]]
}

@test "network.sh dispatcher - a heavy probe keeps its own slow interval" {
  set_tmux_option "@net_revamped_ping_enabled" "1"
  set_tmux_option "@net_revamped_ping_interval" "60"
  export MOCK_EPOCH=1000
  network_refresh
  [[ "$(cache_get ping)" == "9" ]]
  read_ping() { echo "99"; }
  export MOCK_EPOCH=1010
  network_refresh
  [[ "$(cache_get ping)" == "9" ]]
  export MOCK_EPOCH=1100
  network_refresh
  [[ "$(cache_get ping)" == "99" ]]
}

@test "network.sh dispatcher - public_ip refreshes only after its interval" {
  set_tmux_option "@net_revamped_public_ip_enabled" "1"
  set_tmux_option "@net_revamped_public_ip_interval" "300"
  export MOCK_EPOCH=1000
  network_refresh
  [[ "$(cache_get public_ip)" == "198.51.100.9" ]]
  read_public_ip() { echo "203.0.113.1"; }
  export MOCK_EPOCH=1100
  network_refresh
  [[ "$(cache_get public_ip)" == "198.51.100.9" ]]
  export MOCK_EPOCH=1400
  network_refresh
  [[ "$(cache_get public_ip)" == "203.0.113.1" ]]
}

@test "network.sh dispatcher - upload renders the cached rate" {
  export MOCK_EPOCH=1000
  run main upload
  [ "$status" -eq 0 ]
  [[ "$output" == "0B/s" ]]
}

@test "network.sh dispatcher - fg_color routes without error" {
  export MOCK_EPOCH=1000
  run main fg_color
  [ "$status" -eq 0 ]
}

@test "network.sh dispatcher - bg_color routes without error" {
  export MOCK_EPOCH=1000
  run main bg_color
  [ "$status" -eq 0 ]
}

@test "network.sh dispatcher - a metric renders without a label by default" {
  run network_labelled download "42"

  [[ "${output}" == "42" ]]
}

@test "network.sh dispatcher - the nerd icon set labels a metric" {
  set_tmux_option "@net_revamped_icons" "nerd"

  run network_labelled download "42"

  [[ "${output}" == $'\xf3\xb0\x87\x9a'" 42" ]]
}

@test "network.sh dispatcher - a set label beats the icon set" {
  set_tmux_option "@net_revamped_icons" "nerd"
  set_tmux_option "@net_revamped_download_label" "X"

  run network_labelled download "42"

  [[ "${output}" == "X 42" ]]
}

@test "network.sh dispatcher - an empty label removes the icon set's label" {
  set_tmux_option "@net_revamped_icons" "nerd"
  network_option_exists() { [[ "${1}" == "@net_revamped_download_label" ]]; }

  run network_labelled download "42"

  [[ "${output}" == "42" ]]
}

@test "network.sh dispatcher - an empty value renders nothing even with a label" {
  set_tmux_option "@net_revamped_icons" "nerd"

  run network_labelled download ""

  [ -z "${output}" ]
}

@test "network.sh dispatcher - only value metrics carry a label" {
  run network_is_labelled fg_color

  [ "${status}" -eq 1 ]
}

@test "network.sh dispatcher - main labels a rendered metric" {
  set_tmux_option "@net_revamped_icons" "nerd"
  network_render_metric() { echo "42"; }

  run main download

  [[ "${output}" == $'\xf3\xb0\x87\x9a'" 42" ]]
}

@test "network.sh dispatcher - smoothing keeps a burst from jumping the rate" {
  unset EPOCHREALTIME
  set_tmux_option "@net_revamped_smoothing" "50"
  export MOCK_EPOCH=1000
  network_refresh
  NET_RX=5096
  NET_TX=2000
  export MOCK_EPOCH=1002
  network_refresh

  run cache_get down_smooth

  [[ "${output}" == "1024" ]]
}

@test "network.sh dispatcher - a width option pads the value on the left" {
  set_tmux_option "@net_revamped_download_width" "8"

  run network_labelled download "5KB/s"

  [[ "${output}" == "   5KB/s" ]]
}

@test "network.sh dispatcher - a value wider than the width is not cut" {
  set_tmux_option "@net_revamped_download_width" "2"

  run network_labelled download "5KB/s"

  [[ "${output}" == "5KB/s" ]]
}

@test "network.sh dispatcher - a non-numeric width adds no padding" {
  set_tmux_option "@net_revamped_download_width" "wide"

  run network_labelled download "5KB/s"

  [[ "${output}" == "5KB/s" ]]
}

@test "network.sh dispatcher - the padding sits between the label and the value" {
  set_tmux_option "@net_revamped_download_label" "X"
  set_tmux_option "@net_revamped_download_width" "8"

  run network_labelled download "5KB/s"

  [[ "${output}" == "X    5KB/s" ]]
}

@test "network dispatcher - fixed width pads a value to its widest form" {
  set_tmux_option "@net_revamped_fixed_width" "on"

  run network_labelled download "5.0KB/s"

  [[ "${output}" == "  5.0KB/s" ]]
}

@test "network dispatcher - natural widths cover the padded metrics" {
  run bash -c 'source "$1"; for m in download upload ping ip; do printf "%s=%s " "$m" "$(network_natural_width "$m")"; done' _ "${BATS_TEST_DIRNAME}/../../../src/network.sh"

  [[ "${output}" == "download=9 upload=9 ping=5 ip=0 " ]]
}

@test "network dispatcher - publish writes every published metric in one batch" {
  export PUBLISH_LOG="${TEST_TMPDIR}/publish.log"
  _publish_tmux() { [[ "${1}" == "list-clients" ]] && return 0; printf '%s\n' "$@" > "${PUBLISH_LOG}"; }
  network_refresh() { return 0; }
  network_output() { printf 'v-%s' "${1}"; }
  set_tmux_option "@net_revamped_published" "alpha beta"

  network_publish

  [[ "$(paste -sd'|' "${PUBLISH_LOG}")" == "set-option|-gq|@net_revamped_out_alpha|v-alpha|;|set-option|-gq|@net_revamped_out_beta|v-beta" ]]
}

@test "network dispatcher - the daemon re-executes after the tick limit" {
  ticker_run() { return 0; }
  _network_reexec() { echo "reexec" > "${TEST_TMPDIR}/reexec"; }

  network_daemon

  [[ "$(cat "${TEST_TMPDIR}/reexec")" == "reexec" ]]
}

@test "network dispatcher - the daemon stops when it loses ownership" {
  ticker_run() { return 1; }
  _network_reexec() { echo "reexec" > "${TEST_TMPDIR}/reexec"; }

  network_daemon

  [ ! -f "${TEST_TMPDIR}/reexec" ]
}

@test "network dispatcher - main daemon runs the ticker" {
  network_daemon() { echo "daemon" > "${TEST_TMPDIR}/daemon"; }

  main daemon

  [[ "$(cat "${TEST_TMPDIR}/daemon")" == "daemon" ]]
}

@test "network dispatcher - main start spawns the daemon" {
  _ticker_spawn() { printf '%s' "${1}" > "${TEST_TMPDIR}/spawn"; }

  main start

  [[ "$(cat "${TEST_TMPDIR}/spawn")" == *"/src/network.sh" ]]
}
