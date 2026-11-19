#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/network_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/network_helpers.bash"

wired() {
  ip_says route 'default via 192.168.0.1 dev eth0 proto dhcp'
  counters_linux eth0 5204800 3051200
  clock_ns 1000002000000000
  now 1000002
}

everything() {
  wired
  sampled
  ip_says addr '    inet 10.0.0.7/24 brd 10.0.0.255 scope global dynamic eth0'
  ip_says links '5: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420'
  says nmcli 'Office:wireguard'
  says ss 'ESTAB 0 0 10.0.0.7:52000 140.82.112.25:443'
  proc_file wireless 'Inter-| sta-|   Quality        |   Discarded packets
 face | tus | link level noise |  nwid  crypt   frag  retry   misc
  eth0: 0000   58.  -52.  -256        0      0      0      0      0'
  says iwgetid 'Cafe #5'
  counters_linux eth0 5204800 3051200
}

@test "commands - status prints one placeholder from the stored sample" {
  # Arrange
  sampled "1.0KB/s" "512B/s" 1536 1000000

  # Act
  tool status speed

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "1.0KB/s 512B/s" ]]
}

@test "commands - status without a name is a usage error, and an unknown name a bad value" {
  # Arrange
  tool status
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: no placeholder given. run 'network-revamped help' for usage." ]]

  # Act
  tool status latency

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: status must be download, upload, speed, fg_color, bg_color, vpn, vpn_name, ip, wifi, ssid, connections, ping, public_ip or online, got: latency" ]]
}

@test "commands - refresh samples the network now and says what moves" {
  # Arrange
  wired
  tool refresh
  [[ "${output}" == "Refreshed. eth0 moves 0B/s down and 0B/s up." ]]
  sampled

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. eth0 moves 100.0KB/s down and 25.0KB/s up." ]]
}

@test "commands - refresh runs the probes the status line uses and no other" {
  # Arrange
  everything
  option published "speed ip"

  # Act
  tool refresh

  # Assert
  holds ip 10.0.0.7
  holds vpn ""
  holds ssid ""
}

@test "commands - refresh says when no interface has counters, and fails when no tmux server takes the sample" {
  # Arrange
  tool refresh
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. No interface with byte counters was found." ]]
  wired
  : >"${FAKE}/refused"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: no tmux server is running, so the reading has nowhere to go" ]]
}

@test "commands - card reads everything now and prints one row per reading, with the probes that call out named as off" {
  # Arrange
  everything

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Interface          eth0" ]]
  [[ "${lines[1]}" == "Download           100.0KB/s" ]]
  [[ "${lines[2]}" == "Upload             25.0KB/s" ]]
  [[ "${lines[3]}" == "LAN address        10.0.0.7" ]]
  [[ "${lines[4]}" == "Public address     off, set @net_revamped_public_ip_enabled to 1" ]]
  [[ "${lines[5]}" == "VPN link           wg0" ]]
  [[ "${lines[6]}" == "VPN name           Office" ]]
  [[ "${lines[7]}" == "Wi-Fi name         Cafe #5" ]]
  [[ "${lines[8]}" == "Wi-Fi signal       -52 dBm" ]]
  [[ "${lines[9]}" == "Connections        1" ]]
  [[ "${lines[10]}" == "Latency            off, set @net_revamped_ping_enabled to 1" ]]
  [[ "${lines[11]}" == "Internet           off, set @net_revamped_online_enabled to 1" ]]
  [[ "${lines[12]}" == "Read. eth0 is the measured interface." ]]
  [[ "${#lines[@]}" -eq 13 ]]
}

@test "commands - card shows the probes that call out once they are on, and says when the internet is out of reach" {
  # Arrange
  everything
  says ping '64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=12.874 ms'
  curl_says 140.82.112.25 0
  option ping_enabled 1
  option public_ip_enabled 1
  option online_enabled 1
  tool card
  [[ "${lines[4]}" == "Public address     140.82.112.25" ]]
  [[ "${lines[10]}" == "Latency            12 ms" ]]
  [[ "${lines[11]}" == "Internet           reachable" ]]
  curl_says 140.82.112.25 7
  option online_ts ""

  # Act
  tool card

  # Assert
  [[ "${lines[11]}" == "Internet           unreachable" ]]
}

@test "commands - with no interface the card has a dash in every empty row and says so" {
  # Arrange
  local none="Read. No interface carries the default route."

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Interface          -" ]]
  [[ "${lines[1]}" == "Download           -" ]]
  [[ "${lines[8]}" == "Wi-Fi signal       -" ]]
  [[ "${lines[9]}" == "Connections        -" ]]
  [[ "${lines[12]}" == "${none}" ]]
}

@test "commands - where gum draws the card is a table and a closing sentence" {
  # Arrange
  everything
  export REVAMPED_TEST_GUM=1

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Reading"*"Value"* ]]
  [[ "${output}" == *"Download"*"100.0KB/s"* ]]
  [[ "${output}" == *"Read. eth0 is the measured interface."* ]]
}

@test "commands - apply binds the popup key and prints nothing" {
  # Arrange
  local started='^bind-key -N Network details M-e run-shell'

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${started}"
  [[ "${output}" == "1" ]]
}

@test "commands - popup opens the card in a tmux popup and prints nothing" {
  # Arrange
  local opened='^display-popup -E -w 70% -h 80% .* card; '

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${opened}"
  [[ "${output}" == "1" ]]
}

@test "commands - list prints what apply would send, and --json the same plan as one object" {
  # Arrange
  local path
  path=$(bin_path)
  option popup_key 'C-"'
  tool list
  [[ "${output}" == "bind-key -N Network details C-\" run-shell ${path} popup" ]]

  # Act
  tool list --json

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"bindings":[["bind-key","-N","Network details","C-\"","run-shell","'*' popup"]]}' ]]
  run sends
  [[ -z "${output}" ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  sampled

  # Act
  tool --json card

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: option '--json' works only with list. run 'network-revamped help' for usage." ]]
}

@test "commands - the command line wins over the environment, and the environment over the tmux option" {
  # Arrange
  sampled "1.0KB/s" "512B/s" 1536 1000000
  option speed_format 'option %s %s'
  tool status speed
  [[ "${output}" == "option 1.0KB/s 512B/s" ]]
  export NETWORK_REVAMPED_SPEED_FORMAT='environment %s %s'
  tool status speed
  [[ "${output}" == "environment 1.0KB/s 512B/s" ]]

  # Act
  tool --speed-format 'line %s %s' status speed

  # Assert
  [[ "${output}" == "line 1.0KB/s 512B/s" ]]
}

@test "commands - an option takes its value after a space or an equals sign, and an empty label leaves the nerd glyph" {
  # Arrange
  sampled "1.0KB/s" "512B/s" 1536 1000000
  option icons nerd
  tool --download-label=D: status download
  [[ "${output}" == "D: 1.0KB/s" ]]

  # Act
  tool --download-label '' status download

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'\xf3\xb0\x87\x9a 1.0KB/s' ]]
}

@test "commands - an unknown option, one without its value and a word after a double dash are usage errors" {
  # Arrange
  tool --colour red status speed
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: unknown option '--colour'. run 'network-revamped help' for usage." ]]
  tool --colour=red status speed
  [[ "${output}" == "network-revamped: unknown option '--colour'. run 'network-revamped help' for usage." ]]
  tool -x
  [[ "${output}" == "network-revamped: unknown option '-x'. run 'network-revamped help' for usage." ]]
  tool status --interval
  [[ "${output}" == "network-revamped: option '--interval' needs a value. run 'network-revamped help' for usage." ]]

  # Act
  tool -- --interval

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: unknown command '--interval'. run 'network-revamped help' for usage." ]]
}

@test "commands - a bad number is reported alone, since the reader of the environment reads it to the end" {
  # Arrange
  mkdir -p "${BATS_TEST_TMPDIR}/stubs"
  cat >"${BATS_TEST_TMPDIR}/stubs/env" <<'STUB'
#!/bin/sh
{ set +x; } 2>/dev/null
trap '' PIPE
printf 'NETWORK_REVAMPED_INTERVAL=soon\n'
count=0
while [ "${count}" -lt 4000 ]; do
  printf 'FILLER_%s=%0100d\n' "${count}" 0 || exit 1
  count=$((count + 1))
done
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/env"

  # Act
  tool status speed

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: --interval must be a whole number, got: soon" ]]
}

@test "commands - a number is checked before anything runs, whichever setting carries it" {
  # Arrange
  tool --interval soon status speed
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: --interval must be a whole number, got: soon" ]]
  tool --vpn-name-interval often status speed
  [[ "${output}" == "network-revamped: --vpn-name-interval must be a whole number, got: often" ]]
  tool --public-ip-width wide status speed
  [[ "${output}" == "network-revamped: --public-ip-width must be a whole number, got: wide" ]]

  # Act
  tool --high-thresh fast status speed

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: --high-thresh must be a whole number, got: fast" ]]
}

@test "commands - a width given as nothing is no width, and fixed width is a choice, not a number" {
  # Arrange
  sampled "1.0KB/s" "512B/s" 1536 1000000

  # Act
  tool --download-width '' --fixed-width on status download

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "  1.0KB/s" ]]
}

@test "commands - a switch, the precision, the smoothing and each choice are checked before anything runs" {
  # Arrange
  tool --ping-enabled yes status speed
  [[ "${output}" == "network-revamped: --ping-enabled must be 0 or 1, got: yes" ]]
  tool --public-ip-enabled 2 status speed
  [[ "${output}" == "network-revamped: --public-ip-enabled must be 0 or 1, got: 2" ]]
  tool --online-enabled on status speed
  [[ "${output}" == "network-revamped: --online-enabled must be 0 or 1, got: on" ]]
  tool --precision 12 status speed
  [[ "${output}" == "network-revamped: --precision must be a digit from 0 to 9, got: 12" ]]
  tool --smoothing 100 status speed
  [[ "${output}" == "network-revamped: --smoothing must be a whole number from 0 to 99, got: 100" ]]
  tool --icons emoji status speed
  [[ "${output}" == "network-revamped: --icons must be ascii or nerd, got: emoji" ]]
  tool --fixed-width yes status speed
  [[ "${output}" == "network-revamped: --fixed-width must be on or off, got: yes" ]]

  # Act
  tool --render both status speed

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "network-revamped: --render must be jobs or options, got: both" ]]
}

@test "commands - on Linux doctor names each source, the files it reads and a default key someone else holds" {
  # Arrange
  local route='ip +ok +.*/stubs/ip, names the interface of the default route, the VPN link and the LAN address' counters='counters +ok +/proc/net/dev, holds the byte counters' sockets='ss +ok +.*/stubs/ss, counts the established connections' names='nmcli +ok +.*/stubs/nmcli, names the connected VPN' signal='wireless +ok +/proc/net/wireless, holds the Wi-Fi signal' wifi='iwgetid +ok +.*/stubs/iwgetid, reads the Wi-Fi name' held='keys +warn +already bound and left alone: M-e'
  everything
  printf 'bind-key    -T prefix M-e     display-message mine\n' >"${FAKE}/keys"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${route} ]]
  [[ "${output}" =~ ${counters} ]]
  [[ "${output}" =~ ${sockets} ]]
  [[ "${output}" =~ ${names} ]]
  [[ "${output}" =~ ${signal} ]]
  [[ "${output}" =~ ${wifi} ]]
  [[ "${output}" =~ ${held} ]]
}

@test "commands - on Linux doctor prefers netstat for the connections and falls back to iw for the Wi-Fi name" {
  # Arrange
  local sockets='netstat +ok +.*/stubs/netstat, counts the established connections' wifi='iw +ok +.*/stubs/iw, reads the Wi-Fi name'
  netstat_says sockets ''
  says iw ''

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${sockets} ]]
  [[ "${output}" =~ ${wifi} ]]
}

@test "commands - on Linux doctor warns about each source that is missing and exits 0" {
  # Arrange
  local route='ip +warn +without it no interface, VPN link or LAN address is found: apt install iproute2' counters='counters +warn +/proc/net/dev cannot be read, so the rates stay empty' sockets='ss +warn +neither netstat nor ss is installed, so the connections stay empty: apt install iproute2' names='nmcli +warn +without it the VPN name stays empty' signal='wireless +warn +/proc/net/wireless cannot be read, so the Wi-Fi signal stays empty' wifi='iw +warn +neither iwgetid nor iw is installed, so the Wi-Fi name stays empty: apt install iw' free='keys +ok +every key it binds is free or its own'
  proc_file dev ''
  rm -f "${FAKE}/proc.dev"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${route} ]]
  [[ "${output}" =~ ${counters} ]]
  [[ "${output}" =~ ${sockets} ]]
  [[ "${output}" =~ ${names} ]]
  [[ "${output}" =~ ${signal} ]]
  [[ "${output}" =~ ${wifi} ]]
  [[ "${output}" =~ ${free} ]]
}

@test "commands - on macOS doctor names the five system tools it reads" {
  # Arrange
  local route='route +ok +.*/stubs/route, names the interface of the default route' counters='netstat +ok +.*/stubs/netstat, reads the byte counters, the VPN routes and the connections' address='ipconfig +ok +.*/stubs/ipconfig, reads the LAN address' names='scutil +ok +.*/stubs/scutil, names the connected VPN' wifi='system_profiler +ok +.*/stubs/system_profiler, reads the Wi-Fi name and signal'
  macos
  route_is en7
  netstat_says counters ''
  says ipconfig 192.168.0.24
  says scutil ''
  says system_profiler ''

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${route} ]]
  [[ "${output}" =~ ${counters} ]]
  [[ "${output}" =~ ${address} ]]
  [[ "${output}" =~ ${names} ]]
  [[ "${output}" =~ ${wifi} ]]
}

@test "commands - on macOS doctor warns about each system tool that is missing" {
  # Arrange
  local route='route +warn +without it no interface is found, so set @net_revamped_interface' counters='netstat +warn +without it the rates, the VPN link and the connections stay empty' address='ipconfig +warn +without it the LAN address stays empty' names='scutil +warn +without it the VPN name stays empty' wifi='system_profiler +warn +without it the Wi-Fi name and signal stay empty'
  macos

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${route} ]]
  [[ "${output}" =~ ${counters} ]]
  [[ "${output}" =~ ${address} ]]
  [[ "${output}" =~ ${names} ]]
  [[ "${output}" =~ ${wifi} ]]
}

@test "commands - doctor names ping and curl, or what stays empty without them" {
  # Arrange
  local latency='ping +warn +without it the latency stays empty' fetch='curl +warn +without it the public address stays empty and reachability falls back to ping'
  tool doctor
  [[ "${output}" =~ ${latency} ]]
  [[ "${output}" =~ ${fetch} ]]
  says ping ''
  curl_says ''

  # Act
  tool doctor

  # Assert
  [[ "${output}" =~ ping\ +ok\ +.*/stubs/ping,\ measures\ the\ latency\ when\ @net_revamped_ping_enabled\ is\ 1 ]]
  [[ "${output}" =~ curl\ +ok\ +.*/stubs/curl,\ fetches\ the\ public\ address\ and\ tests\ reachability\ when\ their\ options\ are\ 1 ]]
}

@test "commands - doctor says how finely the clock counts: nanoseconds from date, milliseconds from perl, or whole seconds" {
  # Arrange
  local coarse='clock +warn +date counts whole seconds and perl is missing, so a rate can be off by a second of traffic'
  tool doctor
  [[ "${output}" =~ ${coarse} ]]
  clock_ns 17000001234
  tool doctor
  [[ "${output}" =~ ${coarse} ]]
  says perl 1700000123456
  tool doctor
  [[ "${output}" =~ clock\ +ok\ +.*/stubs/perl,\ counts\ milliseconds\ where\ date\ cannot ]]
  clock_ns 1700000123456789012

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ clock\ +ok\ +date\ counts\ nanoseconds,\ so\ a\ rate\ is\ exact\ to\ the\ millisecond ]]
}

@test "commands - doctor names a tmux option whose value it does not know" {
  # Arrange
  option smoothing 150

  # Act
  tool doctor

  # Assert
  run grep '^settings' <<<"${output}"
  [[ "${output}" == "settings           warn     unknown values: smoothing=150" ]]
}
