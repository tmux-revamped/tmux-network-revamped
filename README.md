<div align="center">

# tmux-network-revamped

<strong>Network throughput in your tmux status bar, without ever blocking the render.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-network-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-network-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-network-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-network-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-network-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="network-revamped showing the rates and every probe in the status line, opening the detail popup, switching to Nerd Font labels and to the options render mode" width="800">
</p>

```console
$ network-revamped refresh
Refreshed. en0 moves 55.2KB/s down and 18.4KB/s up.
$ network-revamped status speed
55.2KB/s 18.4KB/s
```

**14** placeholders, **2** render modes, macOS and Linux, tmux **3.2** or later.

---

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor, and the popup |
| curl | optional | `#{net_public_ip}` and `#{net_online}`; without it reachability falls back to ping |
| gum | optional | the menu, tables and colours of `network-revamped`; without it every command prints plain text |

It runs on Linux and macOS with BSD, GNU or uutils coreutils. Each probe uses a tool the OS ships:

| Data | macOS | Linux |
|:-----|:------|:------|
| Byte counters | `netstat -ib` | `/proc/net/dev` |
| Default interface | `route -n get default` | `ip route show default` |
| LAN address | `ipconfig getifaddr` | `ip addr show` |
| VPN interface | `netstat -rn` | `ip -o link show up` |
| VPN name | `scutil --nc list` | `nmcli` |
| Wi-Fi signal and name | `system_profiler SPAirPortDataType` | `/proc/net/wireless`, `iwgetid` or `iw` |
| Connections | `netstat -an` | `netstat -an`, or `ss` |

A missing tool leaves its placeholder empty.

### Install

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

`make install` in the clone also puts `network-revamped` in `~/.local/bin`, with its man page and completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-network-revamped/bin/network-revamped doctor
```

## Usage

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

`@net_revamped_<metric>_label` prints an icon or word before one metric, only when its value is not empty. `@net_revamped_icons` set to `nerd` labels every metric with a Nerd Font glyph. A metric's own label wins over the set. The default, `ascii`, adds no labels.

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

| Command | What it does |
|:--------|:-------------|
| `network-revamped apply` | Binds the popup key and fills the placeholders now; the entry point runs it when tmux loads the plugin |
| `network-revamped list` | Prints every command `apply` would send and changes nothing; `--json` prints one object |
| `network-revamped status NAME` | Prints one placeholder, such as `speed`, `ip` or `ssid`; the status line runs it |
| `network-revamped refresh` | Samples the network now and says what moves |
| `network-revamped card` | Reads everything now and prints one row per reading |
| `network-revamped popup` | Opens the card in a tmux popup; the popup key runs it |
| `network-revamped daemon` | Publishes the placeholders on every tick, for the `options` render mode; `apply` starts it |
| `network-revamped doctor` | One row per dependency: each tool or file a reading comes from, how finely the clock counts, and any key left alone |
| `network-revamped version` | The version, then the tmux version |
| `network-revamped help` | The help page; `man network-revamped` documents the same commands and settings |
| `network-revamped` | On a terminal, a menu |

## Configuration

Every option is also a command option with dashes, such as `--precision 2`, and an environment variable, such as `NETWORK_REVAMPED_PRECISION`; the command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default. `doctor` names any setting that holds a value the plugin does not know. One given to `apply` rides on the popup key and on every status call.

### Sampling

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@net_revamped_interface` | empty | Interface to measure; empty uses the default-route interface |
| `@net_revamped_interval` | `2` | Seconds between rate samples |
| `@net_revamped_precision` | `1` | Decimal places for rates, `0` to `9`; a rate that rounds to 1000 or more moves up a unit, through TB/s |
| `@net_revamped_smoothing` | `0` | Weight in percent, `1` to `99`, of the previous rate in a moving average; `0` shows each sample |
| `@net_revamped_render` | `jobs` | `options` reads published options instead of running `#()` calls |

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

| Key | Action | Default |
|:----|:-------|:--------|
| `prefix + M-e` | Detail popup with every reading; Enter closes it | Bound |

`@net_revamped_popup_key` names another key, and `off` binds none. The default key is left alone when something else already holds it, and `network-revamped doctor` says so.

<a id="how-it-works"></a>

## How it works

[`network-revamped.tmux`](network-revamped.tmux) runs once when tmux loads the plugin. It records which metrics `status-left` and `status-right` use in `@net_revamped_published`, then replaces each placeholder with a call to [`bin/network-revamped`](bin/network-revamped) or, in `options` mode, with an option read and starts the background process.

In the default mode, each `#()` call returns the cached value at once. When the cache is older than its interval, the call starts a refresh in the background and takes a lock, so only one refresh runs at a time. The rate is the change in the interface byte counters divided by the elapsed milliseconds. The previous counters live in tmux options, so no file is written.

SSID, VPN name, VPN interface and LAN address values have every `#` doubled before they reach the status line, so a network named `#(cmd)` prints as text instead of running.

The readers for each tool's output, the sampling and the formatting live in [`lib/network.sh`](lib/network.sh), and the settings table in [`lib/state.sh`](lib/state.sh). A probe runs only for a placeholder the status line uses. The clock counts milliseconds through `date`, or through perl where `date` cannot.

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/speed.png" alt="network-revamped: The rates, coloured by tier, and every probe in the status line"><br><sub>The rates, coloured by tier, and every probe in the status line, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="network-revamped: prefix M-e opens the detail popup"><br><sub><code>prefix M-e</code> opens the detail popup, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="network-revamped: @net_revamped_icons set to nerd labels every metric with a glyph"><br><sub><code>@net_revamped_icons</code> set to <code>nerd</code> labels every metric with a glyph, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/options.png" alt="network-revamped: In the options render mode each placeholder reads a tmux option"><br><sub>In the <code>options</code> render mode each placeholder reads a tmux option, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="network-revamped: card prints every reading"><br><sub><code>card</code> prints every reading, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/precision.png" alt="network-revamped: @net_revamped_precision sets the decimal places of a rate"><br><sub><code>@net_revamped_precision</code> sets the decimal places of a rate, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="network-revamped: @net_revamped_speed_format shapes the speed"><br><sub><code>@net_revamped_speed_format</code> shapes the speed, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="network-revamped: @net_revamped_fixed_width pads each value to its widest form"><br><sub><code>@net_revamped_fixed_width</code> pads each value to its widest form, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="network-revamped: A label of its own before one metric"><br><sub>A label of its own before one metric, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="network-revamped: list prints every binding"><br><sub><code>list</code> prints every binding, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="network-revamped: status speed prints both rates"><br><sub><code>status speed</code> prints both rates, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="network-revamped: doctor"><br><sub><code>doctor</code>, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="network-revamped: The menu without gum"><br><sub>The menu without gum, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="network-revamped: doctor from the menu"><br><sub><code>doctor</code> from the menu, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="network-revamped: The version"><br><sub>The version, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="network-revamped: An unknown command"><br><sub>An unknown command, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="network-revamped: An accent from NETWORK_REVAMPED_ACCENT"><br><sub>An accent from <code>NETWORK_REVAMPED_ACCENT</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="network-revamped: The header in six themes"><br><sub>The header in six themes, from <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="network-revamped: The help page"><br><sub>The help page, from <code>help.tape</code></sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

The recordings run the real plugin and tmux. Small scripts stand in for the network tools, so the rates and addresses on screen are theirs.

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

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
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | **this plugin**, Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
