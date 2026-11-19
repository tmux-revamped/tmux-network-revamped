# tmux-network-revamped

Guidance for anyone, human or agent, changing tmux-network-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-network-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`network-revamped.tmux`](network-revamped.tmux) | The entry point TPM runs: it runs `bin/network-revamped apply` |
| [`bin/network-revamped`](bin/network-revamped) | The command: `apply`, `list`, `status`, `refresh`, `card`, `popup`, `daemon`, `doctor`, `version`, `help` and the menu. `apply`, `status`, `popup` and `daemon` run without loading the interface modules |
| [`lib/network.sh`](lib/network.sh) | Reading the settings and the stored reading, the clock, the counters and the rates, the nine probes, the placeholders with their labels and widths, the publisher's tick, the popup and the binding |
| [`lib/state.sh`](lib/state.sh) | Every global, including `NETWORK_REVAMPED_SETTINGS`, the table of setting names and defaults, and `NETWORK_REVAMPED_LIVE`, the names of the options that hold the reading |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/readers.bats`](test/readers.bats), [`test/network.bats`](test/network.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The clock and each reader on both systems, the rates with the probes and every placeholder, the binding with both render modes, the daemon and the popup, and every command, against a stand-in tmux from [`test/network_helpers.bash`](test/network_helpers.bash) that keeps options in a file, with stand-ins for each network tool, a `cat` that serves the two files under `/proc/net`, and a `date` that answers `+%s%N` |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, with the popup key pressed through a second tmux attached to it, in both render modes; both share [`test/server_helpers.bash`](test/server_helpers.bash), whose clock moves two seconds per sample and whose counters follow it, so the rates on screen are exact |
| [`screens/`](screens) | The tapes and the recording's tmux config. `prepare.sh` copies the plugin to a neutral folder and writes stand-ins for the network tools |
| [`examples/`](examples) | A status line to copy |

## Names

- Settings are the tmux options `@net_revamped_<setting>` listed in `NETWORK_REVAMPED_SETTINGS`, the long options with dashes, such as `--vpn-name-label`, and the environment variables `NETWORK_REVAMPED_<SETTING>`. The option prefix is `net`; the tool and its variables carry `network`.
- The stored reading is `@net_revamped_download`, `_upload`, `_total`, `_down_smooth`, `_up_smooth`, `_rx_raw`, `_tx_raw`, `_sample_ms`, `_download_ts`, `_download_lock` and `_download_lock_ts`, then one option and one `_ts` per probe. `apply` writes `@net_revamped_published`, the daemon `@net_revamped_out_<name>` and `@net_revamped_ticker_pid`. None of them is a setting.
- The placeholders are `#{net_download}`, `#{net_upload}`, `#{net_speed}`, `#{net_fg_color}`, `#{net_bg_color}`, `#{net_vpn}`, `#{net_vpn_name}`, `#{net_ip}`, `#{net_wifi}`, `#{net_ssid}`, `#{net_connections}`, `#{net_ping}`, `#{net_public_ip}` and `#{net_online}`; `status` names each one without the `net_`.
- The version constant is `NETWORK_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.

## Behaviour

- `apply` reads every setting and the stored reading with one `tmux display-message` call and one `env` read, reads the prefix table once, and sends the binding and the replaced status strings in one tmux call. When that call fails, it sends each command alone and `apply` exits 1.
- In `jobs` mode each placeholder in `status-left` or `status-right` becomes `#(<tool> status <name>)`, with the tool's path quoted for a shell and every `#` and `%` doubled, since tmux reads the status line both as a format and as a time format. In `options` mode it becomes `#{E:@net_revamped_out_<name>}`, `apply` starts the daemon, and a status refresh starts no process. A string already rewritten is not written again, and the names it uses stay in `@net_revamped_published`, so loading twice changes nothing.
- `status` makes one tmux read and one `date` call, and prints the stored reading at once. Only when the rates are older than `@net_revamped_interval`, and no sample is under way, does it start one in the background through the shared cache module.
- A sample reads the clock, the interface and its counters, runs the probes that are due, and writes everything in one tmux call. A probe runs only for a placeholder in `@net_revamped_published`, or the one `status` was asked for; `card` runs them all.
- The daemon is the shared ticker: it claims `@net_revamped_ticker_pid`, samples and publishes every name in `@net_revamped_published` in one tmux call per tick, sleeps for the interval, and ends when another process holds the claim or the server is gone. At the ticker's tick cap it starts itself again.
- `M-e` opens `card` in a popup that waits for Enter. A key set to `off` binds nothing. Only the default key is skipped when someone else holds it, and `doctor` names it; a key the person names is bound whoever holds it. On a tmux older than 3.2 the key says why it opens nothing.
- A setting `apply` got from the command line or the environment rides, as an option, on the popup key and on every status call; `NETWORK_REVAMPED_CARRIED` lists the ones that ride. The daemon inherits the environment of the `apply` that started it.

## Domain rules

- A rate is the change in the interface's byte counters times 1000 over the milliseconds between two samples. A counter that went back, a first sample and a missing number all give zero. With smoothing on, the rate kept is that percent of the previous one plus the rest of the new one.
- The clock is `date +%s%N` when it answers with at least 16 digits, else perl's `Time::HiRes`, else whole seconds. `doctor` says which one this machine has.
- The interface is the setting, else the one the default route names: `route -n get default` on macOS, the word after `dev` in `ip route show default` on Linux. The counters come from `netstat -ib` on macOS and `/proc/net/dev` on Linux.
- Each probe has its own interval and its own time option. Ping, the public address and reachability also need their `_enabled` option at `1`, since each one calls out. On macOS the Wi-Fi name and signal share one `system_profiler` run per sample. On Linux the connections come from `netstat`, else `ss`, and the VPN link is a tunnel interface matched on its whole name.
- The VPN link, the VPN name, the LAN address and the Wi-Fi name are stored as read; tmux expands formats in a job's output and in an option read with `E:`, so each `#` in them is doubled when a placeholder prints them. `card` prints them as read, since a terminal expands nothing.
- A label is printed only before a value. In the `nerd` set each metric gets its glyph unless its own label is set; an empty tmux option means its default, so a label set to nothing keeps the glyph and an online text set to nothing prints the default text. An online text given as nothing in the environment prints nothing.
- A value is padded on the left to its own `_width`, else, with `@net_revamped_fixed_width` at `on`, to its widest form: 8 plus the precision for a rate, 7 at precision 0, and 5 for the latency. Width counts characters, and a longer value is never cut.
- The tier is the total rate in KB/s against the two thresholds; the colour placeholders print that tier's style and are never labelled or padded.
- An argument that ends in `;` is sent as `\;`: tmux reads a bare trailing semicolon in an argument as a command separator. The command list keeps an empty argument as the marker in `NETWORK_REVAMPED_EMPTY`; only an empty line ends a command.

## Release

- `NETWORK_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-17:

- No `@net_revamped_notify` for offline, a captive portal or packet loss over the critical level yet.
