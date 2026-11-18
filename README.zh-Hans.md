<div align="center">

# tmux-network-revamped

<strong>在 tmux 状态栏显示网络吞吐量，从不阻塞渲染。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-network-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-network-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-network-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-network-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-network-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="network-revamped 在状态栏中显示网速和各项探测，打开详情弹窗，并切换到 Nerd Font 标签和 options 渲染模式" width="800">
</p>

```console
$ network-revamped refresh
Refreshed. en0 moves 55.2KB/s down and 18.4KB/s up.
$ network-revamped status speed
55.2KB/s 18.4KB/s
```

**14** 个占位符，**2** 种渲染模式，支持 macOS 和 Linux，需要 tmux **3.2** 及以上版本。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族的最低版本，弹窗也需要它 |
| curl | 可选 | 用于 `#{net_public_ip}` 和 `#{net_online}`；没有它时，连通性改用 ping 检测 |
| gum | 可选 | `network-revamped` 的菜单、表格和颜色；没有它，所有命令都输出纯文本 |

可在 Linux 和 macOS 上运行，支持 BSD、GNU 或 uutils coreutils。每个探测都使用操作系统自带的工具：

| 数据 | macOS | Linux |
|:-----|:------|:------|
| 字节计数器 | `netstat -ib` | `/proc/net/dev` |
| 默认接口 | `route -n get default` | `ip route show default` |
| 局域网地址 | `ipconfig getifaddr` | `ip addr show` |
| VPN 接口 | `netstat -rn` | `ip -o link show up` |
| VPN 名称 | `scutil --nc list` | `nmcli` |
| Wi-Fi 信号和名称 | `system_profiler SPAirPortDataType` | `/proc/net/wireless`、`iwgetid` 或 `iw` |
| 连接数 | `netstat -an` | `netstat -an` 或 `ss` |

缺少某个工具时，对应的占位符为空。

### 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把插件加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-network-revamped'
```

手动安装时，克隆仓库，并在 `~/.tmux.conf` 中运行入口脚本：

```bash
git clone https://github.com/tmux-revamped/tmux-network-revamped ~/.tmux/plugins/tmux-network-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-network-revamped/network-revamped.tmux
```

请在插件加载之前设置 `status-left` 或 `status-right`。插件只在加载时替换一次其中的占位符。

在克隆的目录中运行 `make install`，还会把 `network-revamped` 放进 `~/.local/bin`，把它的 man 手册和补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-network-revamped/bin/network-revamped doctor
```

## 用法

插件在状态栏显示下载和上传速率，以及 VPN、局域网地址、已建立的连接数、Wi-Fi 信号强度和网络名称。Ping 延迟、公网地址和互联网连通性需要手动开启，因为它们都会发起网络请求。

| 占位符 | 输出 |
|:-------|:-----|
| `#{net_download}` | 下载速率，例如 `1.2MB/s` |
| `#{net_upload}` | 上传速率，例如 `256.0KB/s` |
| `#{net_speed}` | 按 `@net_revamped_speed_format` 格式化的下载和上传速率 |
| `#{net_fg_color}` | 当前流量档位的前景样式 |
| `#{net_bg_color}` | 当前流量档位的背景样式 |
| `#{net_vpn}` | 活动的 VPN 接口，例如 `utun3` 或 `wg0`；没有时为空 |
| `#{net_vpn_name}` | VPN 连接名称，macOS 上来自 `scutil`，Linux 上来自 `nmcli` |
| `#{net_ip}` | 默认路由接口的 IPv4 地址 |
| `#{net_connections}` | 已建立的连接数 |
| `#{net_ping}` | 到 `8.8.8.8` 的延迟，需手动开启 |
| `#{net_public_ip}` | 公网 IPv4 地址，需手动开启 |
| `#{net_wifi}` | Wi-Fi 信号强度，例如 `-55dBm` |
| `#{net_ssid}` | 当前 Wi-Fi 网络名称 |
| `#{net_online}` | 表示互联网连通性的 `on` 或 `off`，需手动开启 |

在状态栏中放入占位符：

```tmux
set -g @net_revamped_low_fg_color '#[fg=green]'
set -g @net_revamped_medium_fg_color '#[fg=yellow]'
set -g @net_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{net_fg_color}#{net_speed}#[default] '
```

同样的示例见 [examples/status-right.tmux.conf](examples/status-right.tmux.conf)。

开启会发起网络请求的探测：

```tmux
set -g @net_revamped_ping_enabled '1'
set -g @net_revamped_public_ip_enabled '1'
set -g @net_revamped_online_enabled '1'
```

### 标签和宽度

`@net_revamped_<metric>_label` 只在值不为空时，在该指标前显示一个图标或文字。把 `@net_revamped_icons` 设为 `nerd` 后，每个指标都会带上 Nerd Font 图标。单个指标的标签优先于这套图标。默认值 `ascii` 不添加标签。

| 指标 | `nerd` 图标 |
|:-----|:------------|
| `download` | U+F01DA |
| `upload` | U+F0552 |
| `speed` | U+F04E2 |
| `vpn`、`vpn_name` | U+F0582 |
| `ip` | U+F0A60 |
| `wifi`、`ssid` | U+F05A9 |
| `connections` | U+F0318 |
| `ping` | U+F0003 |
| `public_ip` | U+F01E7 |
| `online` | U+F059F |

把 `@net_revamped_fixed_width` 设为 `on` 后，每个值都会在左侧补空格到其最大宽度，因此速率从 `5.0KB/s` 变为 `142.0KB/s` 时，行内其余内容不会移动。默认精度下速率宽度为 9 个字符，ping 为 5 个字符。`@net_revamped_<metric>_width` 设置单个指标的宽度，优先于固定宽度。较长的值不会被截断。

### 渲染模式

默认情况下，每个占位符会变成一个 `#()` 调用，tmux 每次重绘状态栏时都会重新运行它。把 `@net_revamped_render` 设为 `options` 后，每个占位符会变成读取选项，例如 `#{E:@net_revamped_out_download}`。每个服务器只有一个后台进程，每 `@net_revamped_interval` 秒采样一次，并在一次 tmux 调用中写入所有值，所以这些值会同时更新。

```tmux
set -g @net_revamped_render 'options'
set -g @net_revamped_fixed_width 'on'
```

### 档位颜色

档位样式默认为空，所以在设置之前，`#{net_fg_color}` 和 `#{net_bg_color}` 不输出任何内容。下面的配色把低流量对应绿色，中等对应黄色，高流量对应红色：

| 主题 | 低 | 中 | 高 |
|:-----|:---|:---|:---|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

每个值都写成样式，例如 `set -g @net_revamped_low_fg_color '#[fg=#a6e3a1]'`。

| 命令 | 作用 |
|:--------|:-------------|
| `network-revamped apply` | 立即绑定弹窗按键并替换占位符；插件加载时入口点会运行它 |
| `network-revamped list` | 打印 `apply` 会发送的每条命令，不做任何修改；`--json` 输出一个对象 |
| `network-revamped status NAME` | 打印一个占位符，例如 `speed`、`ip` 或 `ssid`；状态栏会运行它 |
| `network-revamped refresh` | 立即对网络采样，并说明当前的速率 |
| `network-revamped card` | 立即读取所有数据，每项占一行 |
| `network-revamped popup` | 在 tmux 弹窗中打开卡片；弹窗按键会运行它 |
| `network-revamped daemon` | 为 `options` 渲染模式在每个周期发布占位符；由 `apply` 启动 |
| `network-revamped doctor` | 每个依赖一行：每项数据所用的工具或文件、时钟的精度，以及未改动的按键 |
| `network-revamped version` | 版本号和 tmux 的版本 |
| `network-revamped help` | 帮助页；`man network-revamped` 记录了同样的命令和设置 |
| `network-revamped` | 在终端上显示菜单 |

## 配置

每个选项也可以写成带连字符的命令选项，例如 `--precision 2`，或环境变量，例如 `NETWORK_REVAMPED_PRECISION`；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示使用默认值。传给 `apply` 的选项会随弹窗按键和每次状态调用一起生效。

### 采样

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@net_revamped_interface` | 空 | 要测量的接口；为空时使用默认路由接口 |
| `@net_revamped_interval` | `2` | 速率采样间隔的秒数 |
| `@net_revamped_precision` | `1` | 速率的小数位数，`0` 到 `9`；四舍五入后达到 1000 及以上时进一个单位，最高到 TB/s |
| `@net_revamped_smoothing` | `0` | 移动平均中上一次速率所占的百分比权重，`1` 到 `99`；`0` 显示每次采样的原值 |
| `@net_revamped_render` | `jobs` | 设为 `options` 时读取发布的选项，而不运行 `#()` 调用 |

### 探测

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@net_revamped_ping_enabled` | `0` | 设为 `1` 时 ping `8.8.8.8` |
| `@net_revamped_public_ip_enabled` | `0` | 设为 `1` 时从 `icanhazip.com` 获取公网地址 |
| `@net_revamped_online_enabled` | `0` | 设为 `1` 时请求 `https://www.gstatic.com/generate_204`，没有 curl 时改用 ping |
| `@net_revamped_<probe>_interval` | `30` | 单个探测的运行间隔秒数，适用于 `vpn`、`vpn_name`、`ip`、`connections`、`wifi`、`ssid`、`online` |
| `@net_revamped_ping_interval` | `15` | ping 探测的间隔秒数 |
| `@net_revamped_public_ip_interval` | `300` | 获取公网地址的间隔秒数 |
| `@net_revamped_online_interval` | `30` | 连通性探测的间隔秒数 |

### 格式和标签

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@net_revamped_speed_format` | `%s %s` | 依次接收下载和上传速率的 `printf` 格式 |
| `@net_revamped_ping_format` | `%sms` | 延迟的 `printf` 格式 |
| `@net_revamped_wifi_format` | `%sdBm` | 信号强度的 `printf` 格式 |
| `@net_revamped_online_up_text` | `on` | 可连通时显示的文字 |
| `@net_revamped_online_down_text` | `off` | 不可连通时显示的文字；仅在开启探测时显示 |
| `@net_revamped_icons` | `ascii` | 设为 `nerd` 时为每个指标加上 Nerd Font 图标 |
| `@net_revamped_<metric>_label` | 空 | 显示在单个指标前的标签 |
| `@net_revamped_fixed_width` | `off` | 设为 `on` 时把每个值补齐到最大宽度 |
| `@net_revamped_<metric>_width` | 空 | 单个指标的宽度 |

### 流量档位

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@net_revamped_medium_thresh` | `100` | 进入中等档位的下载与上传合计速率，单位 KB/s |
| `@net_revamped_high_thresh` | `1000` | 进入高档位的下载与上传合计速率，单位 KB/s |
| `@net_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 各档位下 `#{net_fg_color}` 和 `#{net_bg_color}` 输出的样式 |

### 内部状态

以下选项由插件自己写入，请勿设置。

| 选项 | 保存内容 |
|:-----|:---------|
| `@net_revamped_published` | 加载时在状态栏中找到的指标 |
| `@net_revamped_out_<metric>` | `options` 模式下每个指标渲染后的值 |
| `@net_revamped_ticker_pid` | `options` 模式后台进程的进程 ID |
| `@net_revamped_option_names` | 该后台进程每次读取的选项名称 |
| `@net_revamped_<key>`、`_ts`、`_lock` | 缓存的值、其时间戳和刷新锁，包括上一次的字节计数器 |

## 按键绑定

| 按键 | 动作 | 默认 |
|:-----|:-----|:-----|
| `prefix + M-e` | 显示所有数据的详情弹窗；按 Enter 关闭 | 已绑定 |

`@net_revamped_popup_key` 可以指定其他按键，设为 `off` 则不绑定。默认按键已被占用时不会改动它，`network-revamped doctor` 会说明这一点。

<a id="工作原理"></a>

## 工作原理

tmux 加载插件时，[`network-revamped.tmux`](network-revamped.tmux) 会运行一次。它把 `status-left` 和 `status-right` 用到的指标记录到 `@net_revamped_published`，然后把每个占位符替换为对 [`bin/network-revamped`](bin/network-revamped) 的调用；在 `options` 模式下则替换为读取选项，并启动后台进程。

默认模式下，每个 `#()` 调用会立即返回缓存的值。缓存超过其间隔时，调用会获取锁并在后台开始刷新，因此同一时间只有一个刷新在运行。速率等于接口字节计数器的变化量除以经过的毫秒数。上一次的计数器保存在 tmux 选项中，因此不会写入任何文件。

SSID、VPN 名称、VPN 接口和局域网地址在进入状态栏之前，其中每个 `#` 都会被加倍，所以名为 `#(cmd)` 的网络只会显示为文字，而不会被执行。

读取各工具输出、采样和格式化的代码位于 [`lib/network.sh`](lib/network.sh)，设置表位于 [`lib/state.sh`](lib/state.sh)。只有状态栏用到的占位符才会运行对应的探测。时钟通过 `date` 精确到毫秒，`date` 做不到时改用 perl。

<a id="界面"></a>

## 界面

<details>
<summary>所有界面，在真实的 tmux 中用 <code>make screens</code> 录制，每个按键显示在状态栏上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/speed.png" alt="network-revamped：按档位着色的速率，以及状态栏中的各项探测"><br><sub>按档位着色的速率，以及状态栏中的各项探测，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="network-revamped：prefix M-e 打开详情弹窗"><br><sub><code>prefix M-e</code> 打开详情弹窗，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="network-revamped：把 @net_revamped_icons 设为 nerd，每个指标前都有图标"><br><sub>把 <code>@net_revamped_icons</code> 设为 <code>nerd</code>，每个指标前都有图标，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/options.png" alt="network-revamped：在 options 渲染模式下，每个占位符读取一个 tmux 选项"><br><sub>在 <code>options</code> 渲染模式下，每个占位符读取一个 tmux 选项，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="network-revamped：card 打印所有数据"><br><sub><code>card</code> 打印所有数据，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/precision.png" alt="network-revamped：@net_revamped_precision 设置速率的小数位数"><br><sub><code>@net_revamped_precision</code> 设置速率的小数位数，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="network-revamped：@net_revamped_speed_format 设置速度的格式"><br><sub><code>@net_revamped_speed_format</code> 设置速度的格式，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="network-revamped：@net_revamped_fixed_width 把每个值补齐到最宽的形式"><br><sub><code>@net_revamped_fixed_width</code> 把每个值补齐到最宽的形式，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="network-revamped：给单个指标加上自己的标签"><br><sub>给单个指标加上自己的标签，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="network-revamped：list 打印所有绑定"><br><sub><code>list</code> 打印所有绑定，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="network-revamped：status speed 打印上下行速率"><br><sub><code>status speed</code> 打印上下行速率，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="network-revamped：doctor"><br><sub><code>doctor</code>，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="network-revamped：没有 gum 时的菜单"><br><sub>没有 gum 时的菜单，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="network-revamped：从菜单运行 doctor"><br><sub>从菜单运行 <code>doctor</code>，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="network-revamped：版本"><br><sub>版本，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="network-revamped：未知命令"><br><sub>未知命令，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="network-revamped：来自 NETWORK_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>NETWORK_REVAMPED_ACCENT</code> 的强调色，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="network-revamped：六种主题下的标题"><br><sub>六种主题下的标题，来自 <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="network-revamped：帮助页"><br><sub>帮助页，来自 <code>help.tape</code></sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

录制时运行的是真实的插件和 tmux。网络工具由小脚本代替，所以画面上的速率和地址来自这些脚本。

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | **本插件**，在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
