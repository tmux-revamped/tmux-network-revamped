# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `@net_revamped_render 'options'` replaces the `#()` calls with tmux option
  reads, written by one background process per server every
  `@net_revamped_interval` seconds, 2 by default. tmux reruns a `#()` call on every redraw, so a
  shared bar ran each one about once a second and painted values one by one.
- `@net_revamped_fixed_width 'on'` pads each value to its widest form, and
  `@net_revamped_<metric>_width` sets one metric's width, so a value changing
  length no longer shifts the rest of the status line.
- `@net_revamped_precision`, the decimal places for the rates. A rate that
  rounds to 1000 or more moves up a unit, through GB/s.
- `@net_revamped_smoothing`, an exponential moving average over the rates, so
  bursty traffic reads as a trend instead of jumping every sample. Off by
  default.
- Metric labels. `@net_revamped_<metric>_label` prints an icon or word before a value
  only when the value is not empty, and `@net_revamped_icons` set to `nerd` labels
  every metric from a Nerd Font set. The default adds no labels.

### Changed

- The options-mode background process reads every option it needs in one tmux
  call per tick, sends its cache writes and published values in a second, and
  keeps its functions out of the environment of the commands it runs. Options
  mode ticks every `@net_revamped_interval` seconds.

### Fixed

- In options mode, running the entry point a second time, as two overlapping
  config reloads do, found no placeholders left in the status line and
  published nothing, which froze every value. A metric whose option read is
  already on the status line now counts as used.
- The Wi-Fi, SSID, LAN IP, VPN and connection probes refreshed on every
  sample, and the Wi-Fi and SSID probes run `system_profiler`, about 0.16 s of
  CPU each. They now refresh every 30 seconds, set per probe with
  `@net_revamped_<probe>_interval`.
- A comma-decimal locale printed rates as `2,0KB/s`. The formatter now runs
  under the C locale.
- The rate divided by whole seconds between samples taken two to five seconds
  apart, so a sample 2.9 seconds after the last one was divided by 2 and read
  about 45 percent high. Samples are now timed in milliseconds from bash 5's
  `EPOCHREALTIME`, falling back to whole seconds on older bash.

## [1.4.0] - 2026-06-29

### Added

- `#{net_ssid}` shows the current Wi-Fi network name. macOS reads the
  `system_profiler SPAirPortDataType` current-network block, and Linux prefers
  `iwgetid -r` with an `iw dev link` fallback. Each probe is feature-detected
  and the token is empty when no tool reports a network.
- `#{net_online}` is now wired into the status interpolation, so the documented
  reachability token renders.

### Changed

- The heavy opt-in probes `#{net_ping}`, `#{net_public_ip}`, and `#{net_online}`
  refresh on their own intervals instead of the fast speed cadence. New options
  `@net_revamped_ping_interval`, `@net_revamped_public_ip_interval`, and
  `@net_revamped_online_interval` default to 15, 300, and 30 seconds, so speed
  stays responsive while a slow probe no longer fires on every sample.

## [1.3.0] - 2026-06-23

### Added

- `#{net_online}` reachability indicator. It probes over HTTP first, which keeps
  working on corporate networks that drop ICMP, and falls back to ping when curl
  is missing. Opt-in via `@net_revamped_online_enabled` (upstream
  tmux-online-status #16).

### Changed

- Reviewed the upstream tmux-net-speed and tmux-online-status issues. Throughput
  is measured on the single default-route interface, so bonded interfaces are
  never double-counted (#12), and the worker runs once per refresh with no
  process leak. Wi-Fi signal (#13) and macOS support are already shipped.

## [1.2.0] - 2026-06-20

### Added

- LAN IPv4 `#{net_ip}` of the active interface, from `ipconfig getifaddr` on
  macOS and `ip addr show` on Linux.
- Human VPN connection name `#{net_vpn_name}`, from `scutil --nc list` on macOS
  and `nmcli` on Linux. Both run as cheap local probes that always refresh.

## [1.1.0] - 2026-06-20

### Added

- VPN interface `#{net_vpn}` and established-connection count `#{net_connections}`,
  both from cheap local probes that always run.
- Wifi signal strength `#{net_wifi}` in dBm, from system_profiler on macOS and
  /proc/net/wireless on Linux.
- Opt-in `#{net_ping}` latency and `#{net_public_ip}`, gated behind options since
  they make network calls, and run only inside the background worker.

## [1.0.0] - 2026-06-19

### Added

- Network throughput placeholders: `#{net_download}`, `#{net_upload}`,
  `#{net_speed}`, `#{net_fg_color}`, `#{net_bg_color}`.
- Non-blocking design: counters are read in a background worker and the rate is
  read from a tmux user-option. The previous counters are stored in tmux options
  too, so the delta is computed without any temp file.
- macOS via `netstat -ib`, Linux via `/proc/net/dev`, with default-route
  interface detection.
- Configurable interface, interval, format, and color thresholds.
