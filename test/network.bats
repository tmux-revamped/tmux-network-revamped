#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/network_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/network_helpers.bash"

shown() {
  lib_run network 'network_revamped_load; network_revamped_show '"$1"
}

status_of() {
  lib_run network 'network_revamped_status '"$1"
}

refreshed() {
  lib_run network 'network_revamped_load; NETWORK_REVAMPED_WANT="'"${1:-}"'"; network_revamped_refresh'
}

wired() {
  ip_says route 'default via 192.168.0.1 dev eth0 proto dhcp'
  counters_linux eth0 "${1:-5204800}" "${2:-3051200}"
  clock_ns 1000002000000000
  now 1000002
}

@test "network - a rate is the bytes moved over the milliseconds passed, and zero when a number is missing or the counter went back" {
  # Arrange
  local script='for args in "5200000 5000000 2000" "5000000 5200000 2000" "5200000 5000000 0" "x 5000000 2000" "5200000 x 2000" "5200000 5000000 x"; do network_revamped_rate ${args}; printf "[%s]" "${NETWORK_REVAMPED_RATE}"; done'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${output}" == "[100000][0][0][0][0][0]" ]]
}

@test "network - smoothing keeps its percent of the previous rate, and zero, a hundred, junk or no previous rate keep the sample" {
  # Arrange
  local script='for weight in 50 25 0 100 x; do NETWORK_REVAMPED_S_smoothing="${weight}"; network_revamped_smooth 3000 1000; printf "[%s]" "${NETWORK_REVAMPED_SMOOTH}"; done; NETWORK_REVAMPED_S_smoothing=50; network_revamped_smooth 3000 ""; printf "[%s]" "${NETWORK_REVAMPED_SMOOTH}"'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${output}" == "[2000][2500][3000][3000][3000][3000]" ]]
}

@test "network - a rate is printed in the unit that keeps it under a thousand, at the precision asked" {
  # Arrange
  local script='network_revamped_rates 512 1536 1; network_revamped_rates 1000 1048576 1; network_revamped_rates 1300 1023999 0; network_revamped_rates 1536 5368709120 2; network_revamped_rates 1023999 0 1; network_revamped_rates 2199023255552 1125899906842624 1'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${lines[*]}" == "512B/s 1.5KB/s 1.0KB/s 1.0MB/s 1KB/s 1MB/s 1.50KB/s 5.00GB/s 1.0MB/s 0B/s 2.0TB/s 1024.0TB/s" ]]
}

@test "network - a precision that is not one digit means one decimal place" {
  # Arrange
  local script='for precision in 0 3 9 10 x ""; do NETWORK_REVAMPED_S_precision="${precision}"; network_revamped_precision; printf "[%s]" "${NETWORK_REVAMPED_PLACES}"; done'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${output}" == "[0][3][9][1][1][1]" ]]
}

@test "network - a sample stores both rates, their total and the counters in one tmux call" {
  # Arrange
  wired
  sampled

  # Act
  refreshed

  # Assert
  [[ "${status}" -eq 0 ]]
  holds download "100.0KB/s"
  holds upload "25.0KB/s"
  holds total 128000
  holds down_smooth 102400
  holds up_smooth 25600
  holds rx_raw 5204800
  holds tx_raw 3051200
  holds sample_ms 1000002000
  holds download_ts 1000002
  run sends
  [[ "${#lines[@]}" -eq 1 ]]
}

@test "network - the first sample has nothing to compare with, so both rates are zero" {
  # Arrange
  wired

  # Act
  refreshed

  # Assert
  holds download "0B/s"
  holds upload "0B/s"
  holds total 0
  holds sample_ms 1000002000
}

@test "network - a counter that went back, as after a reconnect, gives a rate of zero" {
  # Arrange
  wired 1000 3051200
  sampled

  # Act
  refreshed

  # Assert
  holds download "0B/s"
  holds upload "25.0KB/s"
  holds total 25600
}

@test "network - with smoothing on, a sample is averaged with the rate before it" {
  # Arrange
  wired
  sampled
  option down_smooth 2048
  option up_smooth 0
  option smoothing 50

  # Act
  refreshed

  # Assert
  holds download "51.0KB/s"
  holds upload "12.5KB/s"
  holds total 65024
  holds down_smooth 52224
  holds up_smooth 12800
}

@test "network - without byte counters the rates are cleared and the sample is still timed" {
  # Arrange
  sampled
  now 1000005

  # Act
  refreshed

  # Assert
  holds download ""
  holds upload ""
  holds total ""
  holds down_smooth ""
  holds sample_ms ""
  holds download_ts 1000005
}

@test "network - only the probes whose placeholders are in use run, each stored with its time" {
  # Arrange
  wired
  ip_says addr '    inet 10.0.0.7/24 brd 10.0.0.255 scope global dynamic eth0'
  ip_says links '5: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420'
  says nmcli 'Office:wireguard'
  says iwgetid 'Cafe'

  # Act
  refreshed "ip vpn"

  # Assert
  holds ip 10.0.0.7
  holds ip_ts 1000002
  holds vpn wg0
  holds vpn_ts 1000002
  holds vpn_name ""
  holds ssid ""
  run grep -c -e '^nmcli' -e '^iwgetid' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
}

@test "network - a probe younger than its interval is kept, and its interval, junk there or no time decide the rest" {
  # Arrange
  wired
  ip_says links '5: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420'
  option vpn tun0
  option vpn_ts 999982
  refreshed vpn
  holds vpn tun0
  option vpn_interval 10
  refreshed vpn
  holds vpn wg0
  option vpn tun0
  option vpn_ts 999982
  option vpn_interval soon
  refreshed vpn
  holds vpn tun0
  option vpn_ts 999962
  refreshed vpn
  holds vpn wg0
  option vpn tun0
  option vpn_ts never

  # Act
  refreshed vpn

  # Assert
  holds vpn wg0
  holds vpn_ts 1000002
}

@test "network - the three probes that call out stay off until their options turn them on" {
  # Arrange
  wired
  says ping '64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=12.874 ms'
  curl_says 140.82.112.25 0
  refreshed "ping public_ip online"
  [[ ! -s "${FAKE}/asked" ]] || ! grep -q -e '^ping' -e '^curl' "${FAKE}/asked"
  holds ping ""
  option ping_enabled 1
  option public_ip_enabled 1
  option online_enabled 1

  # Act
  refreshed "ping public_ip online"

  # Assert
  holds ping 12
  holds ping_ts 1000002
  holds public_ip 140.82.112.25
  holds public_ip_ts 1000002
  holds online up
  holds online_ts 1000002
}

@test "network - the remaining probes store the VPN name, the connections, the signal and the Wi-Fi name" {
  # Arrange
  wired
  says nmcli 'Office:wireguard'
  says ss 'ESTAB 0 0 10.0.0.7:52000 140.82.112.25:443'
  proc_file wireless 'Inter-| sta-|   Quality        |   Discarded packets
 face | tus | link level noise |  nwid  crypt   frag  retry   misc
  eth0: 0000   58.  -52.  -256        0      0      0      0      0'
  says iwgetid 'Cafe #5'
  counters_linux eth0 5204800 3051200

  # Act
  refreshed "vpn_name connections wifi ssid"

  # Assert
  holds vpn_name Office
  holds connections 1
  holds wifi -52
  holds ssid "Cafe #5"
  holds ssid_ts 1000002
}

@test "network - the rates and the speed print the stored sample, the speed in its format" {
  # Arrange
  sampled "1.0KB/s" "512B/s" 1536
  shown download
  [[ "${output}" == "1.0KB/s" ]]
  shown upload
  [[ "${output}" == "512B/s" ]]
  shown speed
  [[ "${output}" == "1.0KB/s 512B/s" ]]
  option speed_format '%s down, %s up'

  # Act
  shown speed

  # Assert
  [[ "${output}" == "1.0KB/s down, 512B/s up" ]]
}

@test "network - with no sample stored the rates, the speed and the colours print nothing" {
  # Arrange
  option low_fg_color '#[fg=green]'
  local script='network_revamped_load; for metric in download upload speed fg_color bg_color; do network_revamped_show "${metric}"; done; printf "[end]\n"'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${output}" == "[end]" ]]
}

@test "network - the colour placeholders print the style of the tier the total falls in" {
  # Arrange
  option low_fg_color '#[fg=green]'
  option medium_fg_color '#[fg=yellow]'
  option high_fg_color '#[fg=red]'
  option low_bg_color '#[bg=black]'
  option medium_bg_color '#[bg=blue]'
  option high_bg_color '#[bg=white]'
  local script='network_revamped_load; for total in 1536 204800 2097152; do NETWORK_REVAMPED_S_total="${total}"; network_revamped_show fg_color; network_revamped_show bg_color; done'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${lines[*]}" == "#[fg=green] #[bg=black] #[fg=yellow] #[bg=blue] #[fg=red] #[bg=white]" ]]
}

@test "network - the tiers start where their options say, and junk there means 100 and 1000 KB/s" {
  # Arrange
  option low_fg_color low
  option medium_fg_color medium
  option high_fg_color high
  option medium_thresh 1
  option high_thresh 4
  local script='network_revamped_load; for total in 1000 1536 4096; do NETWORK_REVAMPED_S_total="${total}"; network_revamped_show fg_color; done; NETWORK_REVAMPED_S_medium_thresh=x; NETWORK_REVAMPED_S_high_thresh=y; for total in 4096 204800 2097152; do NETWORK_REVAMPED_S_total="${total}"; network_revamped_show fg_color; done'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${lines[*]}" == "low medium high low medium high" ]]
}

@test "network - text from outside is printed with each hash doubled" {
  # Arrange
  option vpn 'utun#4'
  option vpn_name 'Office #1'
  option ip '10.0.0.7'
  option ssid 'Cafe #5'
  local script='network_revamped_load; for metric in vpn vpn_name ip ssid; do network_revamped_show "${metric}"; done'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${lines[0]}" == "utun##4" ]]
  [[ "${lines[1]}" == "Office ##1" ]]
  [[ "${lines[2]}" == "10.0.0.7" ]]
  [[ "${lines[3]}" == "Cafe ##5" ]]
}

@test "network - the signal and the latency take their formats, and the counts print as stored" {
  # Arrange
  option wifi -52
  option ping 12
  option connections 37
  option public_ip 140.82.112.25
  shown wifi
  [[ "${output}" == "-52dBm" ]]
  shown ping
  [[ "${output}" == "12ms" ]]
  shown connections
  [[ "${output}" == "37" ]]
  shown public_ip
  [[ "${output}" == "140.82.112.25" ]]
  option wifi_format '%s dB'
  option ping_format '~%s'
  shown wifi
  [[ "${output}" == "-52 dB" ]]

  # Act
  shown ping

  # Assert
  [[ "${output}" == "~12" ]]
}

@test "network - a probe with nothing stored prints nothing" {
  # Arrange
  local script='network_revamped_load; for metric in vpn vpn_name ip wifi ssid connections ping public_ip online; do network_revamped_show "${metric}"; done; printf "[end]\n"'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${output}" == "[end]" ]]
}

@test "network - online prints its up text when reachable, and its down text only while the probe is on" {
  # Arrange
  option online up
  shown online
  [[ "${output}" == "on" ]]
  option online_up_text yes
  shown online
  [[ "${output}" == "yes" ]]
  option online ""
  shown online
  [[ -z "${output}" ]]
  option online_enabled 1
  shown online
  [[ "${output}" == "off" ]]
  option online_down_text no

  # Act
  shown online

  # Assert
  [[ "${output}" == "no" ]]
}

@test "network - an online text set to nothing in tmux means its default, and one given as nothing in the environment prints nothing" {
  # Arrange
  option online up
  option online_up_text ''
  shown online
  [[ "${output}" == "on" ]]
  export NETWORK_REVAMPED_ONLINE_UP_TEXT=""

  # Act
  shown online

  # Assert
  [[ -z "${output}" ]]
}

@test "network - a metric's label is printed before its value, and never alone" {
  # Arrange
  sampled
  option download_label 'D:'
  option ssid_label 'W:'
  shown ssid
  [[ -z "${output}" ]]

  # Act
  shown download

  # Assert
  [[ "${output}" == "D: 1.0KB/s" ]]
}

@test "network - the nerd set puts its glyph before every metric" {
  # Arrange
  sampled
  option icons nerd
  option vpn utun4
  option vpn_name Office
  option ip 10.0.0.7
  option wifi -52
  option ssid Cafe
  option connections 37
  option ping 12
  option public_ip 140.82.112.25
  option online up
  local script='network_revamped_load; for metric in download upload speed vpn vpn_name ip wifi ssid connections ping public_ip online; do network_revamped_show "${metric}"; done'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${lines[0]}" == $'\xf3\xb0\x87\x9a 1.0KB/s' ]]
  [[ "${lines[1]}" == $'\xf3\xb0\x95\x92 512B/s' ]]
  [[ "${lines[2]}" == $'\xf3\xb0\x93\xa2 1.0KB/s 512B/s' ]]
  [[ "${lines[3]}" == $'\xf3\xb0\x96\x82 utun4' ]]
  [[ "${lines[4]}" == $'\xf3\xb0\x96\x82 Office' ]]
  [[ "${lines[5]}" == $'\xf3\xb0\xa9\xa0 10.0.0.7' ]]
  [[ "${lines[6]}" == $'\xf3\xb0\x96\xa9 -52dBm' ]]
  [[ "${lines[7]}" == $'\xf3\xb0\x96\xa9 Cafe' ]]
  [[ "${lines[8]}" == $'\xf3\xb0\x8c\x98 37' ]]
  [[ "${lines[9]}" == $'\xf3\xb0\x80\x83 12ms' ]]
  [[ "${lines[10]}" == $'\xf3\xb0\x87\xa7 140.82.112.25' ]]
  [[ "${lines[11]}" == $'\xf3\xb0\x96\x9f on' ]]
}

@test "network - in the nerd set a metric's own label wins, and a label set to nothing means the default, so its glyph stays" {
  # Arrange
  sampled
  option icons nerd
  option download_label 'D:'
  option upload_label ''
  local script='network_revamped_load; network_revamped_show download; network_revamped_show upload; network_revamped_show speed'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${lines[0]}" == "D: 1.0KB/s" ]]
  [[ "${lines[1]}" == $'\xf3\xb0\x95\x92 512B/s' ]]
  [[ "${lines[2]}" == $'\xf3\xb0\x93\xa2 1.0KB/s 512B/s' ]]
}

@test "network - the plain set labels nothing" {
  # Arrange
  sampled

  # Act
  shown download

  # Assert
  [[ "${output}" == "1.0KB/s" ]]
}

@test "network - fixed width pads a rate and the latency on the left to their widest form" {
  # Arrange
  sampled
  option ping 12
  option ssid Cafe
  option fixed_width on
  shown download
  [[ "${output}" == "  1.0KB/s" ]]
  shown ping
  [[ "${output}" == " 12ms" ]]
  shown ssid
  [[ "${output}" == "Cafe" ]]
  option precision 0
  shown upload
  [[ "${output}" == " 512B/s" ]]
  option precision 2

  # Act
  shown upload

  # Assert
  [[ "${output}" == "    512B/s" ]]
}

@test "network - a metric's own width wins over the fixed width, counts characters and never cuts" {
  # Arrange
  sampled
  option fixed_width on
  option download_width 12
  option ssid 'Café'
  option ssid_width 6
  option upload_width 3
  option ping 12
  option ping_width wide
  shown download
  [[ "${output}" == "     1.0KB/s" ]]
  shown ssid
  [[ "${output}" == "  Café" ]]
  shown upload
  [[ "${output}" == "512B/s" ]]

  # Act
  shown ping

  # Assert
  [[ "${output}" == " 12ms" ]]
}

@test "network - a label goes before the padded value" {
  # Arrange
  sampled
  option download_label 'D:'
  option download_width 10

  # Act
  shown download

  # Assert
  [[ "${output}" == "D:    1.0KB/s" ]]
}

@test "network - a fresh sample is printed with one tmux read and no write" {
  # Arrange
  sampled "1.0KB/s" "512B/s" 1536 999999

  # Act
  status_of speed

  # Assert
  [[ "${output}" == "1.0KB/s 512B/s" ]]
  run sends
  [[ -z "${output}" ]]
  run sent '^display-message -p'
  [[ "${output}" == "1" ]]
}

@test "network - a sample older than the interval is printed at once while the network is read behind it" {
  # Arrange
  wired
  sampled "1.0KB/s" "512B/s" 1536 999990

  # Act
  status_of download

  # Assert
  [[ "${output}" == "1.0KB/s" ]]
  eventually holds download "100.0KB/s"
  eventually holds download_lock 0
  holds download_ts 1000002
}

@test "network - with nothing stored yet the placeholder is empty and the first sample starts" {
  # Arrange
  wired

  # Act
  status_of speed

  # Assert
  [[ -z "${output}" ]]
  eventually holds download "0B/s"
}

@test "network - a sample under way is left to finish, and one whose lock is old or has no time is started again" {
  # Arrange
  wired
  sampled "1.0KB/s" "512B/s" 1536 999900
  option download_lock 1
  option download_lock_ts 999997
  status_of download
  run sends
  [[ -z "${output}" ]]
  option download_lock_ts 999970
  status_of download
  eventually holds download "100.0KB/s"
  eventually holds download_lock 0
  sampled "1.0KB/s" "512B/s" 1536 999900
  option download_lock 1
  option download_lock_ts ""

  # Act
  status_of download

  # Assert
  eventually holds download "100.0KB/s"
}

@test "network - the interval comes from its setting, and junk there means two seconds" {
  # Arrange
  wired
  sampled "1.0KB/s" "512B/s" 1536 999962
  option interval 60
  status_of download
  run sends
  [[ -z "${output}" ]]
  option interval soon

  # Act
  status_of download

  # Assert
  eventually holds download "100.0KB/s"
}

@test "network - a placeholder asked for by hand has its probe run even when the status line does not use it" {
  # Arrange
  wired
  says iwgetid 'Cafe'
  sampled "1.0KB/s" "512B/s" 1536 999990
  option published speed

  # Act
  status_of ssid

  # Assert
  [[ -z "${output}" ]]
  eventually holds ssid Cafe
}

@test "network - a tick samples the network and publishes every metric the status line uses in one tmux call" {
  # Arrange
  wired
  sampled
  says iwgetid '50% #1'
  option published "speed ssid"
  printf 'client-a\n' >"${FAKE}/clients"

  # Act
  lib_run network 'network_revamped_tick'

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_speed "100.0KB/s 25.0KB/s"
  holds out_ssid "50%% ##1"
  run sent 'set-option -gq @net_revamped_out_speed 100.0KB/s 25.0KB/s ; set-option -gq @net_revamped_out_ssid 50%% ##1 ; refresh-client -S -t client-a'
  [[ "${output}" == "1" ]]
}

@test "network - a tick skips a doubled space in the list of metrics" {
  # Arrange
  wired
  sampled
  option published "download  upload"

  # Act
  lib_run network 'network_revamped_tick'

  # Assert
  holds out_download "100.0KB/s"
  holds out_upload "25.0KB/s"
  run sent '@net_revamped_out_ '
  [[ "${output}" == "0" ]]
}

@test "network - a tick publishes nothing when the status line uses no metric, or when tmux takes no write" {
  # Arrange
  wired
  lib_run network 'network_revamped_tick'
  run sent '@net_revamped_out_'
  [[ "${output}" == "0" ]]
  option published "speed"
  : >"${FAKE}/refused"

  # Act
  lib_run network 'network_revamped_tick'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent '@net_revamped_out_'
  [[ "${output}" == "0" ]]
}

@test "network - a tmux version is read out of its banner and compared part by part" {
  # Arrange
  local script='for banner in "tmux 3.6a" "tmux next-3.7" "nonsense"; do printf "[%s]" "$(network_revamped_parse_version "${banner}")"; done; for pair in "3.6 3.2" "3.2 3.2" "3.1 3.2" "4.0 3.2" "2.9 3.2" " 3.2" "x 3.2"; do if network_revamped_version_ge ${pair}; then printf y; else printf n; fi; done'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${output}" == "[3.6][3.7][]yynynnn" ]]
}
