#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/network_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/network_helpers.bash"

reads() {
  lib_run network 'NETWORK_REVAMPED_IFACE='"${2:-}"'; network_revamped_read_'"$1"'; printf "[%s]\n" "${NETWORK_REVAMPED_READ}"'
}

clock() {
  lib_run network 'network_revamped_clock; printf "%s %s\n" "${NETWORK_REVAMPED_MS}" "${NETWORK_REVAMPED_NOW}"'
}

iface() {
  lib_run network "${1:-}"'network_revamped_iface; printf "[%s]\n" "${NETWORK_REVAMPED_IFACE}"'
}

counters() {
  lib_run network 'NETWORK_REVAMPED_IFACE='"$1"'; network_revamped_counters; printf "[%s][%s]\n" "${NETWORK_REVAMPED_RX}" "${NETWORK_REVAMPED_TX}"'
}

@test "readers - a date that counts nanoseconds gives the clock in milliseconds and in seconds" {
  # Arrange
  clock_ns 1700000123456789012

  # Act
  clock

  # Assert
  [[ "${output}" == "1700000123456 1700000123" ]]
}

@test "readers - where date cannot count below a second, perl gives the milliseconds" {
  # Arrange
  says perl 1700000123456

  # Act
  clock

  # Assert
  [[ "${output}" == "1700000123456 1700000123" ]]
}

@test "readers - with neither, the clock is whole seconds, and a short or empty answer from date changes nothing" {
  # Arrange
  now 1700000123
  clock
  [[ "${output}" == "1700000123000 1700000123" ]]
  clock_ns 17000001234
  clock
  [[ "${output}" == "1700000123000 1700000123" ]]
  clock_ns ''

  # Act
  clock

  # Assert
  [[ "${output}" == "1700000123000 1700000123" ]]
}

@test "readers - a perl that answers junk leaves the clock at whole seconds" {
  # Arrange
  now 1700000123
  says perl oops

  # Act
  clock

  # Assert
  [[ "${output}" == "1700000123000 1700000123" ]]
}

@test "readers - the interface comes from its setting before any route is asked" {
  # Arrange
  route_is en0
  macos

  # Act
  iface 'NETWORK_REVAMPED_S_interface=en5; '

  # Assert
  [[ "${output}" == "[en5]" ]]
  [[ ! -s "${FAKE}/asked" ]]
}

@test "readers - on macOS the interface is the one route names for the default route" {
  # Arrange
  route_is en7
  macos

  # Act
  iface

  # Assert
  [[ "${output}" == "[en7]" ]]
}

@test "readers - on Linux the interface is the word after dev in the default route, with or without a gateway" {
  # Arrange
  ip_says route 'default via 192.168.0.1 dev wlp3s0 proto dhcp metric 600'
  iface
  [[ "${output}" == "[wlp3s0]" ]]
  ip_says route 'default dev wg0 scope link'

  # Act
  iface

  # Assert
  [[ "${output}" == "[wg0]" ]]
}

@test "readers - with no default route and no route tool there is no interface" {
  # Arrange
  iface
  [[ "${output}" == "[]" ]]
  macos

  # Act
  iface

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - on macOS the byte counters are the interface's link row of netstat" {
  # Arrange
  counters_macos en7 5000000 3000000
  macos

  # Act
  counters en7

  # Assert
  [[ "${output}" == "[5000000][3000000]" ]]
}

@test "readers - on Linux the byte counters are the first and ninth numbers of the interface's row" {
  # Arrange
  counters_linux wlp3s0 7654321 1234567

  # Act
  counters wlp3s0

  # Assert
  [[ "${output}" == "[7654321][1234567]" ]]
}

@test "readers - an interface the system does not list, an unreadable table and no interface give no counters" {
  # Arrange
  counters_linux wlp3s0 7654321 1234567
  counters eth9
  [[ "${output}" == "[][]" ]]
  counters ''
  [[ "${output}" == "[][]" ]]
  rm -f "${FAKE}/proc.dev"
  counters wlp3s0
  [[ "${output}" == "[][]" ]]
  macos

  # Act
  counters en7

  # Assert
  [[ "${output}" == "[][]" ]]
}

@test "readers - the VPN link is the first tunnel in the IPv4 routes on macOS" {
  # Arrange
  netstat_says routes 'Destination        Gateway            Flags               Netif Expire
default            192.168.0.1        UGScg                 en7
10.8.0.0/24        10.8.0.5           UGSc                utun4
10.9.0.0/24        10.9.0.5           UGSc                 ppp0'
  macos

  # Act
  reads vpn

  # Assert
  [[ "${output}" == "[utun4]" ]]
}

@test "readers - the VPN link is the first tunnel interface that is up on Linux, whatever follows its name" {
  # Arrange
  ip_says links '1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
2: wlp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
5: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN
6: tailscale0@if3: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280'

  # Act
  reads vpn

  # Assert
  [[ "${output}" == "[wg0]" ]]
}

@test "readers - with no tunnel there is no VPN link on either system" {
  # Arrange
  ip_says links '2: wlp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP'
  reads vpn
  [[ "${output}" == "[]" ]]
  netstat_says routes 'default            192.168.0.1        UGScg                 en7'
  macos

  # Act
  reads vpn

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - the VPN name is the connected service of scutil on macOS" {
  # Arrange
  says scutil 'Available network connection services in the current set (*=enabled):
* (Disconnected)   11111111-2222-3333-4444-555555555555 PPP --> L2TP   "Home"    [PPP:L2TP]
* (Connected)      66666666-7777-8888-9999-000000000000 VPN (io.wireguard) "Office #1" [VPN:io.wireguard]'
  macos

  # Act
  reads vpn_name

  # Assert
  [[ "${output}" == "[Office #1]" ]]
}

@test "readers - the VPN name is the active vpn or wireguard connection of nmcli on Linux" {
  # Arrange
  says nmcli 'Wired connection 1:802-3-ethernet
Office:wireguard
Backup:vpn'

  # Act
  reads vpn_name

  # Assert
  [[ "${output}" == "[Office]" ]]
}

@test "readers - the LAN address comes from ipconfig on macOS and from the inet row of ip on Linux" {
  # Arrange
  says ipconfig 192.168.0.24
  macos
  reads ip en7
  [[ "${output}" == "[192.168.0.24]" ]]
  grep -qxF 'ipconfig getifaddr en7' "${FAKE}/asked"
  linux
  ip_says addr '2: wlp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether aa:bb:cc:dd:ee:ff brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.7/24 brd 10.0.0.255 scope global dynamic wlp3s0
    inet6 fe80::1/64 scope link'

  # Act
  reads ip wlp3s0

  # Assert
  [[ "${output}" == "[10.0.0.7]" ]]
  grep -qxF 'ip addr show dev wlp3s0' "${FAKE}/asked"
}

@test "readers - with no interface, or a tool that fails, there is no LAN address" {
  # Arrange
  says ipconfig 192.168.0.24
  macos
  reads ip ''
  [[ "${output}" == "[]" ]]
  quiet ipconfig 'exit 1'

  # Act
  reads ip en7

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - the connections are the ESTABLISHED rows of netstat" {
  # Arrange
  netstat_says sockets 'Active Internet connections (including servers)
tcp4       0      0  192.168.0.24.52000     140.82.112.25.443      ESTABLISHED
tcp4       0      0  192.168.0.24.52001     140.82.112.26.443      ESTABLISHED
tcp4       0      0  *.22                   *.*                    LISTEN
tcp6       0      0  ::1.52002              ::1.8080               ESTABLISHED'

  # Act
  reads connections

  # Assert
  [[ "${output}" == "[3]" ]]
}

@test "readers - without netstat the connections are the rows ss lists as established, and with neither there are none" {
  # Arrange
  says ss 'ESTAB 0 0 192.168.0.24:52000 140.82.112.25:443
ESTAB 0 0 192.168.0.24:52001 140.82.112.26:443'
  reads connections
  [[ "${output}" == "[2]" ]]
  grep -qxF 'ss -Htan state established' "${FAKE}/asked"
  rm -f "${BATS_TEST_TMPDIR}/stubs/ss"

  # Act
  reads connections

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - on macOS the Wi-Fi signal and name come from one system_profiler run" {
  # Arrange
  says system_profiler 'Wi-Fi:
      Interfaces:
        en0:
          Status: Connected
          Current Network Information:
            Cafe #5:
              PHY Mode: 802.11ax
              Signal / Noise: -52 dBm / -95 dBm
          Other Local Wi-Fi Networks:
            Neighbour:
              Signal / Noise: -80 dBm / -95 dBm'
  macos
  local script='NETWORK_REVAMPED_AIRPORT_READ=0; network_revamped_read_wifi; printf "[%s]" "${NETWORK_REVAMPED_READ}"; network_revamped_read_ssid; printf "[%s]\n" "${NETWORK_REVAMPED_READ}"'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${output}" == "[-52][Cafe #5]" ]]
  run grep -c '^system_profiler' "${FAKE}/asked"
  [[ "${output}" == "1" ]]
}

@test "readers - off Wi-Fi on macOS there is no signal and no name" {
  # Arrange
  says system_profiler 'Wi-Fi:
      Interfaces:
        en0:
          Status: Off'
  macos
  reads wifi
  [[ "${output}" == "[]" ]]

  # Act
  reads ssid

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - on Linux the signal is the level column of the wireless table" {
  # Arrange
  proc_file wireless 'Inter-| sta-|   Quality        |   Discarded packets               | Missed | WE
 face | tus | link level noise |  nwid  crypt   frag  retry   misc | beacon | 22
wlp3s0: 0000   58.  -52.  -256        0      0      0      0      0        0'

  # Act
  reads wifi

  # Assert
  [[ "${output}" == "[-52]" ]]
}

@test "readers - on Linux the Wi-Fi name comes from iwgetid, and from iw when iwgetid has none" {
  # Arrange
  says iwgetid 'Cafe #5  '
  reads ssid wlp3s0
  [[ "${output}" == "[Cafe #5]" ]]
  says iwgetid ''
  says iw 'Connected to aa:bb:cc:dd:ee:ff (on wlp3s0)
	SSID: Library 2
	freq: 5180'

  # Act
  reads ssid wlp3s0

  # Assert
  [[ "${output}" == "[Library 2]" ]]
  grep -qxF 'iw dev wlp3s0 link' "${FAKE}/asked"
}

@test "readers - with no name from iwgetid and no interface, iw is not asked" {
  # Arrange
  says iw '	SSID: Library 2'

  # Act
  reads ssid ''

  # Assert
  [[ "${output}" == "[]" ]]
  [[ ! -s "${FAKE}/asked" ]]
}

@test "readers - the latency is the whole milliseconds of one ping, asked with each system's own deadline option" {
  # Arrange
  says ping 'PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=12.874 ms'
  macos
  reads ping
  [[ "${output}" == "[12]" ]]
  grep -qxF 'ping -c 1 -t 1 8.8.8.8' "${FAKE}/asked"
  linux

  # Act
  reads ping

  # Assert
  [[ "${output}" == "[12]" ]]
  grep -qxF 'ping -c 1 -w 1 8.8.8.8' "${FAKE}/asked"
}

@test "readers - a ping that gets no answer gives no latency" {
  # Arrange
  quiet ping 'printf "PING 8.8.8.8 (8.8.8.8): 56 data bytes\n"; exit 2'

  # Act
  reads ping

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - the public address is kept only when the answer is one IPv4 address" {
  # Arrange
  curl_says 140.82.112.25
  reads public_ip
  [[ "${output}" == "[140.82.112.25]" ]]
  grep -qxF 'curl -sf --connect-timeout 2 -m 3 https://icanhazip.com' "${FAKE}/asked"
  curl_says '<html>captive portal</html>'

  # Act
  reads public_ip

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - the machine is online when curl reaches the probe page, and not when it fails" {
  # Arrange
  curl_says '' 0
  reads online
  [[ "${output}" == "[up]" ]]
  grep -qxF 'curl -sf -o /dev/null --connect-timeout 2 -m 3 https://www.gstatic.com/generate_204' "${FAKE}/asked"
  curl_says '' 7

  # Act
  reads online

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - without curl the machine is online when a ping answers" {
  # Arrange
  says ping '64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=3.1 ms'
  reads online
  [[ "${output}" == "[up]" ]]
  quiet ping 'exit 2'

  # Act
  reads online

  # Assert
  [[ "${output}" == "[]" ]]
}
