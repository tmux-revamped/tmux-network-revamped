#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin" "${demo}/net" "${demo}/tmux-network-revamped"
cp -Rpf "${SCREENS_REPO}/bin" "${SCREENS_REPO}/lib" "${SCREENS_REPO}/network-revamped.tmux" "${demo}/tmux-network-revamped/"
tmux_path=$(command -v tmux)
ln -s "${tmux_path}" "${demo}/bin/tmux"

cat >"${demo}/bin/netstat" <<'COUNTERS'
#!/bin/sh
folder=/Users/Shared/demo/net
case "$*" in
-ib)
  stamp=$(date +%s%N 2>/dev/null) || stamp=""
  case "${stamp}" in
  *[!0-9]* | "") now=$(($(date +%s) * 1000)) ;;
  *) now="${stamp%??????}" ;;
  esac
  last="${now}" rx=734003200 tx=104857600
  [ ! -f "${folder}/counters" ] || read -r last rx tx <"${folder}/counters"
  case "$(((now / 5000) % 4))" in
  0) down=61440 up=20480 ;;
  1) down=430080 up=92160 ;;
  2) down=2411520 up=184320 ;;
  *) down=870400 up=61440 ;;
  esac
  rx=$((rx + (now - last) * down / 1000))
  tx=$((tx + (now - last) * up / 1000))
  printf '%s %s %s\n' "${now}" "${rx}" "${tx}" >"${folder}/counters.next"
  mv -f "${folder}/counters.next" "${folder}/counters"
  printf 'Name       Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll\n'
  printf 'en0        1500  <Link#12>   aa:bb:cc:dd:ee:ff     2000     0 %s     1500     0 %s     0\n' "${rx}" "${tx}"
  ;;
"-rn -f inet")
  printf 'Destination        Gateway            Flags               Netif Expire\n'
  printf 'default            192.168.1.1        UGScg                 en0\n'
  printf '10.8.0.0/24        10.8.0.5           UGSc                utun4\n'
  ;;
*) awk 'BEGIN { for (i = 0; i < 42; i++) { print "tcp4       0      0  192.168.1.24." 50000 + i "     140.82.112.3.443       ESTABLISHED" } }' ;;
esac
COUNTERS

cat >"${demo}/bin/route" <<'ROUTE'
#!/bin/sh
printf '   route to: default\n  interface: en0\n'
ROUTE

cat >"${demo}/bin/ipconfig" <<'ADDRESS'
#!/bin/sh
printf '192.168.1.24\n'
ADDRESS

cat >"${demo}/bin/scutil" <<'VPN'
#!/bin/sh
printf 'Available network connection services in the current set (*=enabled):\n'
printf '* (Connected)      66666666-7777-8888-9999-000000000000 VPN (io.wireguard) "Office" [VPN:io.wireguard]\n'
VPN

cat >"${demo}/bin/system_profiler" <<'WIFI'
#!/bin/sh
printf 'Wi-Fi:\n      Interfaces:\n        en0:\n          Current Network Information:\n            Studio:\n              Signal / Noise: -52 dBm / -95 dBm\n'
WIFI

cat >"${demo}/bin/ping" <<'LATENCY'
#!/bin/sh
printf '64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=12.874 ms\n'
LATENCY

cat >"${demo}/bin/curl" <<'FETCH'
#!/bin/sh
case "$*" in
*generate_204*) exit 0 ;;
*) printf '140.82.112.3\n' ;;
esac
FETCH
chmod +x "${demo}/bin/netstat" "${demo}/bin/route" "${demo}/bin/ipconfig" "${demo}/bin/scutil" "${demo}/bin/system_profiler" "${demo}/bin/ping" "${demo}/bin/curl"
