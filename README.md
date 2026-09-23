<div align="center">

<h1>tmux-network-revamped</h1>

**Network throughput in your tmux status bar, without ever blocking the render.**

[![Tests](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.4.0-blue.svg)](CHANGELOG.md)

</div>

**12** placeholders · **2** platforms · **143** tests · **95%+** coverage

Surfaces network throughput, VPN interface and name, LAN IP, established connections, ping latency, public IP, and wifi signal in your tmux status bar. A detached background worker reads interface byte counters and computes the rate; the status line reads the formatted result from a tmux server user-option and returns instantly. Previous counters live in tmux options too, so the delta needs no temp file.

Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

<table>
<tr>
<td><strong>Non-blocking</strong><br/>The status line reads a cached value from a tmux user-option and returns instantly.</td>
<td><strong>No temp files</strong><br/>Previous counters live in tmux options, so the rate delta needs no scratch file.</td>
</tr>
<tr>
<td><strong>Cross-platform</strong><br/>macOS and Linux on both Intel and ARM with built-in tools, no extra package.</td>
<td><strong>Tested</strong><br/>108 [bats](https://github.com/bats-core/bats-core) tests hold 95%+ coverage across every probe.</td>
</tr>
</table>

## Placeholders

| Placeholder | Output |
|-------------|--------|
| `#{net_download}` | download rate, for example `1.2MB/s` |
| `#{net_upload}` | upload rate, for example `256.0KB/s` |
| `#{net_speed}` | download and upload together |
| `#{net_fg_color}` | foreground color for the current tier |
| `#{net_bg_color}` | background color for the current tier |
| `#{net_vpn}` | active VPN interface, empty when none |
| `#{net_vpn_name}` | human VPN connection name, needs `scutil` on macOS or `nmcli` on Linux |
| `#{net_ip}` | LAN IPv4 of the active interface |
| `#{net_connections}` | count of established connections |
| `#{net_ping}` | latency to 8.8.8.8, opt-in |
| `#{net_public_ip}` | public IPv4 address, opt-in |
| `#{net_wifi}` | wifi signal strength in dBm, for example `-55dBm` |
| `#{net_ssid}` | current Wi-Fi network name, empty when unavailable |
| `#{net_online}` | reachability state, `on` or `off`, opt-in |

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'tmux-revamped/tmux-network-revamped'
set -g status-right '#{net_fg_color}#{net_speed}'
```

Press `prefix + I` to install.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@net_revamped_interface` | auto | the interface to measure; empty auto-detects the default route |
| `@net_revamped_interval` | `2` | seconds between samples, also the rate window |
| `@net_revamped_speed_format` | `%s %s` | format for download and upload |
| `@net_revamped_medium_thresh` | `100` | total kilobytes per second for the medium tier |
| `@net_revamped_high_thresh` | `1000` | total kilobytes per second for the high tier |
| `@net_revamped_{low,medium,high}_{fg,bg}_color` | empty | tier colors |
| `@net_revamped_ping_enabled` | `0` | set to `1` to probe ping latency (makes a network call) |
| `@net_revamped_ping_format` | `%sms` | format for the ping latency |
| `@net_revamped_ping_interval` | `15` | seconds between ping probes, independent of the speed sample |
| `@net_revamped_public_ip_enabled` | `0` | set to `1` to fetch the public IP (makes a network call) |
| `@net_revamped_public_ip_interval` | `300` | seconds between public IP fetches, independent of the speed sample |
| `@net_revamped_wifi_format` | `%sdBm` | format for the wifi signal |
| `@net_revamped_online_enabled` | `0` | set to `1` to probe internet reachability over HTTP, which works where corporate firewalls drop ICMP (makes a network call) |
| `@net_revamped_online_up_text` | `on` | label shown when reachable |
| `@net_revamped_online_down_text` | `off` | label shown when not reachable |
| `@net_revamped_online_interval` | `30` | seconds between reachability probes, independent of the speed sample |
| `@net_revamped_enable_logging` | `0` | set to `1` to log under `~/.tmux/network-revamped-logs` |

## Theme color suggestions

The defaults use the 16 ANSI color names, which the active terminal theme remaps, so the tiers match any theme out of the box. For exact hex values, copy one block below. Low traffic maps to green, medium to yellow, and high to red.

### Catppuccin Mocha

```tmux
set -g @net_revamped_low_fg_color '#[fg=#a6e3a1]'
set -g @net_revamped_medium_fg_color '#[fg=#f9e2af]'
set -g @net_revamped_high_fg_color '#[fg=#f38ba8]'
```

### Dracula

```tmux
set -g @net_revamped_low_fg_color '#[fg=#50fa7b]'
set -g @net_revamped_medium_fg_color '#[fg=#f1fa8c]'
set -g @net_revamped_high_fg_color '#[fg=#ff5555]'
```

### Nord

```tmux
set -g @net_revamped_low_fg_color '#[fg=#a3be8c]'
set -g @net_revamped_medium_fg_color '#[fg=#ebcb8b]'
set -g @net_revamped_high_fg_color '#[fg=#bf616a]'
```

### Gruvbox Dark

```tmux
set -g @net_revamped_low_fg_color '#[fg=#b8bb26]'
set -g @net_revamped_medium_fg_color '#[fg=#fabd2f]'
set -g @net_revamped_high_fg_color '#[fg=#fb4934]'
```

### Tokyo Night

```tmux
set -g @net_revamped_low_fg_color '#[fg=#9ece6a]'
set -g @net_revamped_medium_fg_color '#[fg=#e0af68]'
set -g @net_revamped_high_fg_color '#[fg=#f7768e]'
```

### Solarized Dark

```tmux
set -g @net_revamped_low_fg_color '#[fg=#859900]'
set -g @net_revamped_medium_fg_color '#[fg=#b58900]'
set -g @net_revamped_high_fg_color '#[fg=#dc322f]'
```

## Support by platform and architecture

Works on every supported platform and architecture with built-in tools, no extra
package required. macOS (Intel and Apple Silicon) reads `netstat -ib`; Linux
(x86_64 and arm64) reads `/proc/net/dev`. The default interface is detected with
`route` on macOS and `ip route` on Linux.

Wifi signal reads `system_profiler SPAirPortDataType` on macOS, which works without
the `airport` binary Apple removed in macOS 14.4, and `/proc/net/wireless` on
Linux. It reports RSSI in dBm; closer to zero is stronger.

## Development

```bash
make test      # run the bats suite
make lint      # shellcheck every script
make coverage  # run the suite under kcov
```

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Fuzzy-grab any URL, path, or word off the screen and paste it, pure shell, no Python |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Jump to any session, window, or pane, or kill it, from one fzf popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Git repository status in your tmux status bar, without ever blocking the render |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, frequency, and memory for your tmux status bar |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in your tmux status bar, async, kubectl-free, never blocking |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | **this plugin**, Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | One plugin that captures every session, window, pane, layout, and working |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | A template for building non-blocking tmux status plugins |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in your tmux status bar, with zero temp files: all state lives in tmux options |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM usage for your tmux status bar, without ever blocking the status render |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to con |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | --- |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local clock and world clocks in your tmux status bar, without ever blocking the render |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather in your tmux status bar, fetched in the background so the render never waits on the network |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
