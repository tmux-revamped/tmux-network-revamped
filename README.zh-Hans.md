<div align="center">

# tmux-network-revamped

<strong>在 tmux 状态栏显示网络吞吐量，从不阻塞渲染。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文（香港）](README.zh-HK.md)

[![family](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/family.yml?branch=main&style=flat-square&label=family)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/family.yml)
[![tests](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/tests.yml?branch=main&style=flat-square&label=tests)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-network-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-network-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-network-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-network-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-network-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#installation">安装</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">配置</a> |
  <a href="#key-bindings">按键绑定</a> |
  <a href="#how-it-works">工作原理</a>
</p>

</div>

**14** 个占位符，**2** 种渲染模式，支持 macOS 和 Linux，需要 tmux **3.2** 及以上版本。

---

<a id="what-it-does"></a>

## 功能

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

<a id="requirements"></a>

## 环境要求

| 依赖 | 版本 |
|:-----|:-----|
| tmux | 3.2 及以上 |
| bash | 3.2 及以上 |
| curl | 任意版本，用于 `#{net_public_ip}` 和 `#{net_online}` |

可在 Linux 和 macOS 上运行，支持 BSD、GNU 或 uutils coreutils。每个探测都使用操作系统自带的工具：

| 数据 | macOS | Linux |
|:-----|:------|:------|
| 字节计数器 | `netstat -ib` | `/proc/net/dev` |
| 默认接口 | `route -n get default` | `ip route show default` |
| 局域网地址 | `ipconfig getifaddr` | `ip addr show` |
| VPN 接口 | `netstat -rn` | `ip -o link show up` |
| VPN 名称 | `scutil --nc list` | `nmcli` |
| Wi-Fi 信号和名称 | `system_profiler SPAirPortDataType` | `/proc/net/wireless`、`iwgetid` 或 `iw` |
| 连接数 | `netstat -an` | `netstat -an` |

缺少某个工具时，对应的占位符为空。

<a id="installation"></a>

## 安装

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

<a id="usage"></a>

## 用法

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

`@net_revamped_<metric>_label` 只在值不为空时，在该指标前显示一个图标或文字。把 `@net_revamped_icons` 设为 `nerd` 后，每个指标都会带上 Nerd Font 图标。单个指标的标签优先于这套图标，设为空标签则去掉该指标的标签。默认值 `ascii` 不添加标签。

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

<a id="configuration"></a>

## 配置

### 采样

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@net_revamped_interface` | 空 | 要测量的接口；为空时使用默认路由接口 |
| `@net_revamped_interval` | `2` | 速率采样间隔的秒数 |
| `@net_revamped_precision` | `1` | 速率的小数位数，`0` 到 `9`；四舍五入后达到 1000 及以上时进一个单位，最高到 GB/s |
| `@net_revamped_smoothing` | `0` | 移动平均中上一次速率所占的百分比权重，`1` 到 `99`；`0` 显示每次采样的原值 |
| `@net_revamped_render` | 空 | 设为 `options` 时读取发布的选项，而不运行 `#()` 调用 |

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

<a id="key-bindings"></a>

## 按键绑定

本插件不绑定任何按键。

<a id="how-it-works"></a>

## 工作原理

tmux 加载插件时，[`network-revamped.tmux`](network-revamped.tmux) 会运行一次。它把 `status-left` 和 `status-right` 用到的指标记录到 `@net_revamped_published`，然后把每个占位符替换为对 [`src/network.sh`](src/network.sh) 的调用；在 `options` 模式下则替换为读取选项，并启动后台进程。

默认模式下，每个 `#()` 调用会立即返回缓存的值。缓存超过其间隔时，调用会获取锁并在后台开始刷新，因此同一时间只有一个刷新在运行。速率等于接口字节计数器的变化量除以经过的毫秒数。上一次的计数器保存在 tmux 选项中，因此不会写入任何文件。

SSID、VPN 名称、VPN 接口和局域网地址在进入状态栏之前，其中每个 `#` 都会被加倍，所以名为 `#(cmd)` 的网络只会显示为文字，而不会被执行。

解析各工具输出的代码位于 [`src/lib/network/network.sh`](src/lib/network/network.sh)，格式化代码位于 [`src/lib/network/render.sh`](src/lib/network/render.sh)。

<a id="development"></a>

## 开发

| 命令 | 作用 |
|:-----|:-----|
| `make test` | 运行 bats 测试套件 |
| `make lint` | 对所有 shell 文件运行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 测量行覆盖率，低于 95% 时失败 |

变更记录见 [CHANGELOG.md](CHANGELOG.md)。

<a id="license"></a>

## 许可证

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中的同一份约定、`family/` 下的同一套工具和同一个共享库，并由校验和清单保证逐字节一致。这些成员可以一起安装：任何成员都不会占用其他成员使用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。这项义务写在约定里，而不是靠记忆，`family/bin/sweep` 负责执行它。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

### 检查安装

所有成员都在磁盘上时，一条命令即可报告它们之间的任何冲突：

```sh
family/bin/doctor --live
```

它读取每个成员和正在运行的 tmux 服务器，报告重复的按键、重复的状态占位符、不符合命名规则的选项，以及约定版本落后的成员。

<!-- family:end -->
