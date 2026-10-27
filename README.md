<div align="center">

# tmux-network-revamped

<strong>Network throughput in your tmux status bar, without ever blocking the render.</strong>

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.5.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">What it does</a> |
  <a href="#installation">Installation</a> |
  <a href="#usage">Usage</a> |
  <a href="#configuration">Configuration</a> |
  <a href="#key-bindings">Key bindings</a> |
  <a href="#how-it-works">How it works</a>
</p>

</div>

**14** placeholders, **2** render modes, macOS and Linux, tmux **3.2** or later.

---

## What it does

The plugin shows download and upload rates in the status line, plus the VPN, LAN address, open connections, Wi-Fi signal and network name. Ping latency, the public address and internet reachability are opt-in, because each one makes a network call.

| Placeholder | Output |
|:------------|:-------|
| `#{net_download}` | Download rate, such as `1.2MB/s` |
| `#{net_upload}` | Upload rate, such as `256.0KB/s` |
| `#{net_speed}` | Download and upload through `@net_revamped_speed_format` |
| `#{net_fg_color}` | Foreground style for the current traffic tier |
| `#{net_bg_color}` | Background style for the current traffic tier |
| `#{net_vpn}` | Active VPN interface, such as `utun3` or `wg0`; empty when none |
| `#{net_vpn_name}` | VPN connection name from `scutil` on macOS or `nmcli` on Linux |
| `#{net_ip}` | IPv4 address of the default-route interface |
| `#{net_connections}` | Number of established connections |
| `#{net_ping}` | Latency to `8.8.8.8`, opt-in |
| `#{net_public_ip}` | Public IPv4 address, opt-in |
| `#{net_wifi}` | Wi-Fi signal strength, such as `-55dBm` |
| `#{net_ssid}` | Current Wi-Fi network name |
| `#{net_online}` | `on` or `off` for internet reachability, opt-in |

## Requirements

| Requirement | Version |
|:------------|:--------|
| tmux | 3.2 or later |
| bash | 3.2 or later |
| curl | any, for `#{net_public_ip}` and `#{net_online}` |

It runs on Linux and macOS with BSD, GNU or uutils coreutils. Each probe uses a tool the OS ships:

| Data | macOS | Linux |
|:-----|:------|:------|
| Byte counters | `netstat -ib` | `/proc/net/dev` |
| Default interface | `route -n get default` | `ip route show default` |
| LAN address | `ipconfig getifaddr` | `ip addr show` |
| VPN interface | `netstat -rn` | `ip -o link show up` |
| VPN name | `scutil --nc list` | `nmcli` |
| Wi-Fi signal and name | `system_profiler SPAirPortDataType` | `/proc/net/wireless`, `iwgetid` or `iw` |
| Connections | `netstat -an` | `netstat -an` |

A missing tool leaves its placeholder empty.

## Installation

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-network-revamped'
```

To install by hand, clone the repository and run the entrypoint from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-network-revamped ~/.tmux/plugins/tmux-network-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-network-revamped/network-revamped.tmux
```

Set `status-left` or `status-right` before the plugin loads. The plugin replaces the placeholders it finds there once, at load time.

## Usage

Put placeholders in the status line:

```tmux
set -g @net_revamped_low_fg_color '#[fg=green]'
set -g @net_revamped_medium_fg_color '#[fg=yellow]'
set -g @net_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{net_fg_color}#{net_speed}#[default] '
```

The same example is in [examples/status-right.tmux.conf](examples/status-right.tmux.conf).

Turn on the probes that make network calls:

```tmux
set -g @net_revamped_ping_enabled '1'
set -g @net_revamped_public_ip_enabled '1'
set -g @net_revamped_online_enabled '1'
```

### Labels and widths

`@net_revamped_<metric>_label` prints an icon or word before one metric, only when its value is not empty. `@net_revamped_icons` set to `nerd` labels every metric with a Nerd Font glyph. A metric's own label wins over the set, and an empty label removes it for that metric. The default, `ascii`, adds no labels.

| Metric | `nerd` glyph |
|:-------|:-------------|
| `download` | U+F01DA |
| `upload` | U+F0552 |
| `speed` | U+F04E2 |
| `vpn`, `vpn_name` | U+F0582 |
| `ip` | U+F0A60 |
| `wifi`, `ssid` | U+F05A9 |
| `connections` | U+F0318 |
| `ping` | U+F0003 |
| `public_ip` | U+F01E7 |
| `online` | U+F059F |

`@net_revamped_fixed_width` set to `on` pads each value on the left to its widest form, so a rate going from `5.0KB/s` to `142.0KB/s` does not shift the rest of the line. That width is 9 characters for a rate at the default precision and 5 for ping. `@net_revamped_<metric>_width` sets one metric's width and wins over the fixed width. A longer value is never cut.

### Render mode

By default each placeholder becomes a `#()` call, which tmux reruns on status redraws. With `@net_revamped_render` set to `options`, each placeholder becomes an option read such as `#{E:@net_revamped_out_download}`. One background process per server then samples every `@net_revamped_interval` seconds and writes all values in one tmux call, so they change together.

```tmux
set -g @net_revamped_render 'options'
set -g @net_revamped_fixed_width 'on'
```

### Tier colors

The tier styles are empty by default, so `#{net_fg_color}` and `#{net_bg_color}` print nothing until you set them. These palettes map low traffic to green, medium to yellow and high to red:

| Theme | Low | Medium | High |
|:------|:----|:-------|:-----|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

Each value goes in a style, such as `set -g @net_revamped_low_fg_color '#[fg=#a6e3a1]'`.

## Configuration

### Sampling

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@net_revamped_interface` | empty | Interface to measure; empty uses the default-route interface |
| `@net_revamped_interval` | `2` | Seconds between rate samples |
| `@net_revamped_precision` | `1` | Decimal places for rates, `0` to `9`; a rate that rounds to 1000 or more moves up a unit, through GB/s |
| `@net_revamped_smoothing` | `0` | Weight in percent, `1` to `99`, of the previous rate in a moving average; `0` shows each sample |
| `@net_revamped_render` | empty | `options` reads published options instead of running `#()` calls |

### Probes

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@net_revamped_ping_enabled` | `0` | `1` pings `8.8.8.8` |
| `@net_revamped_public_ip_enabled` | `0` | `1` fetches the public address from `icanhazip.com` |
| `@net_revamped_online_enabled` | `0` | `1` requests `https://www.gstatic.com/generate_204`, or pings when curl is missing |
| `@net_revamped_<probe>_interval` | `30` | Seconds between runs of one probe: `vpn`, `vpn_name`, `ip`, `connections`, `wifi`, `ssid`, `online` |
| `@net_revamped_ping_interval` | `15` | Seconds between ping probes |
| `@net_revamped_public_ip_interval` | `300` | Seconds between public address fetches |
| `@net_revamped_online_interval` | `30` | Seconds between reachability probes |

### Formats and labels

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@net_revamped_speed_format` | `%s %s` | `printf` format for download, then upload |
| `@net_revamped_ping_format` | `%sms` | `printf` format for the latency |
| `@net_revamped_wifi_format` | `%sdBm` | `printf` format for the signal |
| `@net_revamped_online_up_text` | `on` | Text when reachable |
| `@net_revamped_online_down_text` | `off` | Text when not reachable; shown only with the probe on |
| `@net_revamped_icons` | `ascii` | `nerd` labels every metric with a Nerd Font glyph |
| `@net_revamped_<metric>_label` | empty | Label printed before one metric |
| `@net_revamped_fixed_width` | `off` | `on` pads every value to its widest form |
| `@net_revamped_<metric>_width` | empty | Width for one metric |

### Traffic tiers

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@net_revamped_medium_thresh` | `100` | Combined download and upload, in KB/s, that starts the medium tier |
| `@net_revamped_high_thresh` | `1000` | Combined download and upload, in KB/s, that starts the high tier |
| `@net_revamped_{low,medium,high}_{fg,bg}_color` | empty | Style printed by `#{net_fg_color}` and `#{net_bg_color}` in each tier |

### Internal state

The plugin writes these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@net_revamped_published` | Metrics found in the status line at load time |
| `@net_revamped_out_<metric>` | Rendered value of each metric in `options` mode |
| `@net_revamped_ticker_pid` | Process id of the `options` mode background process |
| `@net_revamped_option_names` | Option names that background process reads each tick |
| `@net_revamped_<key>`, `_ts`, `_lock` | Cached values, their timestamps and refresh locks, including the previous byte counters |

## Key bindings

The plugin binds no keys.

## How it works

[`network-revamped.tmux`](network-revamped.tmux) runs once when tmux loads the plugin. It records which metrics `status-left` and `status-right` use in `@net_revamped_published`, then replaces each placeholder with a call to [`src/network.sh`](src/network.sh) or, in `options` mode, with an option read and starts the background process.

In the default mode, each `#()` call returns the cached value at once. When the cache is older than its interval, the call starts a refresh in the background and takes a lock, so only one refresh runs at a time. The rate is the change in the interface byte counters divided by the elapsed milliseconds. The previous counters live in tmux options, so no file is written.

SSID, VPN name, VPN interface and LAN address values have every `#` doubled before they reach the status line, so a network named `#(cmd)` prints as text instead of running.

The parsers for each tool's output live in [`src/lib/network/network.sh`](src/lib/network/network.sh) and the formatting in [`src/lib/network/render.sh`](src/lib/network/render.sh).

## Development

| Command | What it does |
|:--------|:-------------|
| `make test` | Runs the bats suite |
| `make lint` | Runs shellcheck on every shell file |
| `make coverage` | Measures line coverage with kcov on Linux and fails below 95% |

Changes are listed in [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE)

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
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | **this plugin**, Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness, CI and family tooling |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
