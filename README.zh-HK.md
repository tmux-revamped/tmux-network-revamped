<div align="center">

# tmux-network-revamped

<strong>在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-network-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-network-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-network-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-network-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-network-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速開始"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a> &nbsp;|&nbsp;
  <a href="#畫面">畫面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="network-revamped 在狀態列中顯示網速及各項探測，開啟詳情彈出視窗，並切換到 Nerd Font 標籤和 options 繪製模式" width="800">
</p>

```console
$ network-revamped refresh
Refreshed. en0 moves 55.2KB/s down and 18.4KB/s up.
$ network-revamped status speed
55.2KB/s 18.4KB/s
```

**14** 個佔位符，**2** 種繪製模式，支援 macOS 和 Linux，需要 tmux **3.2** 或以上版本。

---

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或以上 | 家族的最低版本，彈出視窗亦需要它 |
| curl | 可選 | 用於 `#{net_public_ip}` 和 `#{net_online}`；沒有它時，連線狀態改用 ping 檢測 |
| gum | 可選 | `network-revamped` 的選單、表格及顏色；沒有它，所有命令都輸出純文字 |

可在 Linux 和 macOS 上執行，支援 BSD、GNU 或 uutils coreutils。每個探測都使用作業系統內置的工具：

| 資料 | macOS | Linux |
|:-----|:------|:------|
| 位元組計數器 | `netstat -ib` | `/proc/net/dev` |
| 預設介面 | `route -n get default` | `ip route show default` |
| 區域網絡地址 | `ipconfig getifaddr` | `ip addr show` |
| VPN 介面 | `netstat -rn` | `ip -o link show up` |
| VPN 名稱 | `scutil --nc list` | `nmcli` |
| Wi-Fi 訊號和名稱 | `system_profiler SPAirPortDataType` | `/proc/net/wireless`、`iwgetid` 或 `iw` |
| 連線數目 | `netstat -an` | `netstat -an` 或 `ss` |

缺少某個工具時，相應的佔位符為空。

### 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，將插件加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-network-revamped'
```

手動安裝時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-network-revamped ~/.tmux/plugins/tmux-network-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-network-revamped/network-revamped.tmux
```

請在插件載入之前設定 `status-left` 或 `status-right`。插件只在載入時替換一次其中的佔位符。

在複製的目錄中執行 `make install`，亦會把 `network-revamped` 放入 `~/.local/bin`，並把它的 man 手冊和自動完成放在 `~/.local/share` 下。

### 驗證

```bash
~/.tmux/plugins/tmux-network-revamped/bin/network-revamped doctor
```

## 用法

插件在狀態列顯示下載和上載速率，以及 VPN、區域網絡地址、已建立的連線數目、Wi-Fi 訊號強度和網絡名稱。Ping 延遲、公共地址和互聯網連線狀態須手動開啟，因為它們都會發出網絡請求。

| 佔位符 | 輸出 |
|:-------|:-----|
| `#{net_download}` | 下載速率，例如 `1.2MB/s` |
| `#{net_upload}` | 上載速率，例如 `256.0KB/s` |
| `#{net_speed}` | 按 `@net_revamped_speed_format` 格式化的下載和上載速率 |
| `#{net_fg_color}` | 目前流量級別的前景樣式 |
| `#{net_bg_color}` | 目前流量級別的背景樣式 |
| `#{net_vpn}` | 使用中的 VPN 介面，例如 `utun3` 或 `wg0`；沒有時為空 |
| `#{net_vpn_name}` | VPN 連線名稱，macOS 上來自 `scutil`，Linux 上來自 `nmcli` |
| `#{net_ip}` | 預設路由介面的 IPv4 地址 |
| `#{net_connections}` | 已建立的連線數目 |
| `#{net_ping}` | 到 `8.8.8.8` 的延遲，須手動開啟 |
| `#{net_public_ip}` | 公共 IPv4 地址，須手動開啟 |
| `#{net_wifi}` | Wi-Fi 訊號強度，例如 `-55dBm` |
| `#{net_ssid}` | 目前 Wi-Fi 網絡名稱 |
| `#{net_online}` | 表示互聯網連線狀態的 `on` 或 `off`，須手動開啟 |

在狀態列中放入佔位符：

```tmux
set -g @net_revamped_low_fg_color '#[fg=green]'
set -g @net_revamped_medium_fg_color '#[fg=yellow]'
set -g @net_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{net_fg_color}#{net_speed}#[default] '
```

相同的範例見 [examples/status-right.tmux.conf](examples/status-right.tmux.conf)。

開啟會發出網絡請求的探測：

```tmux
set -g @net_revamped_ping_enabled '1'
set -g @net_revamped_public_ip_enabled '1'
set -g @net_revamped_online_enabled '1'
```

### 標籤和闊度

`@net_revamped_<metric>_label` 只在值不為空時，於該指標前顯示一個圖示或文字。將 `@net_revamped_icons` 設為 `nerd` 後，每個指標都會加上 Nerd Font 圖示。個別指標的標籤優先於這套圖示。預設值 `ascii` 不加任何標籤。

| 指標 | `nerd` 圖示 |
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

將 `@net_revamped_fixed_width` 設為 `on` 後，每個值都會在左邊補上空格至其最大闊度，因此速率由 `5.0KB/s` 變為 `142.0KB/s` 時，行內其餘內容不會移位。預設精度下速率闊度為 9 個字元，ping 為 5 個字元。`@net_revamped_<metric>_width` 設定個別指標的闊度，優先於固定闊度。較長的值不會被截斷。

### 繪製模式

預設情況下，每個佔位符會變成一個 `#()` 呼叫，tmux 每次重繪狀態列時都會重新執行。將 `@net_revamped_render` 設為 `options` 後，每個佔位符會變成讀取選項，例如 `#{E:@net_revamped_out_download}`。每部伺服器只有一個背景程序，每 `@net_revamped_interval` 秒取樣一次，並在一次 tmux 呼叫中寫入所有值，所以這些值會同時更新。

```tmux
set -g @net_revamped_render 'options'
set -g @net_revamped_fixed_width 'on'
```

### 級別顏色

級別樣式預設為空，所以設定之前，`#{net_fg_color}` 和 `#{net_bg_color}` 不會輸出任何內容。以下配色將低流量對應綠色，中等對應黃色，高流量對應紅色：

| 主題 | 低 | 中 | 高 |
|:-----|:---|:---|:---|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

每個值都寫成樣式，例如 `set -g @net_revamped_low_fg_color '#[fg=#a6e3a1]'`。

| 命令 | 作用 |
|:--------|:-------------|
| `network-revamped apply` | 立即綁定彈出視窗的按鍵並替換佔位符；插件載入時入口點會執行它 |
| `network-revamped list` | 列印 `apply` 會傳送的每條命令，不作任何修改；`--json` 輸出一個物件 |
| `network-revamped status NAME` | 列印一個佔位符，例如 `speed`、`ip` 或 `ssid`；狀態列會執行它 |
| `network-revamped refresh` | 立即對網絡取樣，並說明目前的速率 |
| `network-revamped card` | 立即讀取所有數據，每項佔一行 |
| `network-revamped popup` | 在 tmux 彈出視窗中開啟卡片；彈出視窗的按鍵會執行它 |
| `network-revamped daemon` | 為 `options` 繪製模式在每個週期發佈佔位符；由 `apply` 啟動 |
| `network-revamped doctor` | 每個依賴一行：每項數據所用的工具或檔案、時鐘的精確度，以及沒有改動的按鍵 |
| `network-revamped version` | 版本號及 tmux 的版本 |
| `network-revamped help` | 說明頁；`man network-revamped` 記錄了同樣的命令和設定 |
| `network-revamped` | 在終端機上顯示選單 |

## 設定

每個選項亦可寫成帶連字號的命令選項，例如 `--precision 2`，或環境變數，例如 `NETWORK_REVAMPED_PRECISION`；命令列優先於環境變數，環境變數優先於 tmux 選項。空的 tmux 選項表示使用預設值。傳給 `apply` 的選項會隨彈出視窗的按鍵和每次狀態呼叫一同生效。

### 取樣

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@net_revamped_interface` | 空 | 要量度的介面；為空時使用預設路由介面 |
| `@net_revamped_interval` | `2` | 速率取樣的間隔秒數 |
| `@net_revamped_precision` | `1` | 速率的小數位數，`0` 至 `9`；四捨五入後達 1000 或以上時進一個單位，最高至 TB/s |
| `@net_revamped_smoothing` | `0` | 移動平均中上一次速率所佔的百分比權重，`1` 至 `99`；`0` 顯示每次取樣的原值 |
| `@net_revamped_render` | `jobs` | 設為 `options` 時讀取已發佈的選項，而不執行 `#()` 呼叫 |

### 探測

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@net_revamped_ping_enabled` | `0` | 設為 `1` 時 ping `8.8.8.8` |
| `@net_revamped_public_ip_enabled` | `0` | 設為 `1` 時從 `icanhazip.com` 取得公共地址 |
| `@net_revamped_online_enabled` | `0` | 設為 `1` 時請求 `https://www.gstatic.com/generate_204`，沒有 curl 時改用 ping |
| `@net_revamped_<probe>_interval` | `30` | 個別探測的執行間隔秒數，適用於 `vpn`、`vpn_name`、`ip`、`connections`、`wifi`、`ssid`、`online` |
| `@net_revamped_ping_interval` | `15` | ping 探測的間隔秒數 |
| `@net_revamped_public_ip_interval` | `300` | 取得公共地址的間隔秒數 |
| `@net_revamped_online_interval` | `30` | 連線狀態探測的間隔秒數 |

### 格式和標籤

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@net_revamped_speed_format` | `%s %s` | 依次接收下載和上載速率的 `printf` 格式 |
| `@net_revamped_ping_format` | `%sms` | 延遲的 `printf` 格式 |
| `@net_revamped_wifi_format` | `%sdBm` | 訊號強度的 `printf` 格式 |
| `@net_revamped_online_up_text` | `on` | 可連線時顯示的文字 |
| `@net_revamped_online_down_text` | `off` | 無法連線時顯示的文字；只在開啟探測時顯示 |
| `@net_revamped_icons` | `ascii` | 設為 `nerd` 時為每個指標加上 Nerd Font 圖示 |
| `@net_revamped_<metric>_label` | 空 | 顯示在個別指標前的標籤 |
| `@net_revamped_fixed_width` | `off` | 設為 `on` 時將每個值補齊至最大闊度 |
| `@net_revamped_<metric>_width` | 空 | 個別指標的闊度 |

### 流量級別

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@net_revamped_medium_thresh` | `100` | 進入中等級別的下載與上載合計速率，單位 KB/s |
| `@net_revamped_high_thresh` | `1000` | 進入高級別的下載與上載合計速率，單位 KB/s |
| `@net_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 各級別下 `#{net_fg_color}` 和 `#{net_bg_color}` 輸出的樣式 |

### 內部狀態

以下選項由插件自行寫入，請勿設定。

| 選項 | 存放內容 |
|:-----|:---------|
| `@net_revamped_published` | 載入時在狀態列中找到的指標 |
| `@net_revamped_out_<metric>` | `options` 模式下每個指標繪製後的值 |
| `@net_revamped_ticker_pid` | `options` 模式背景程序的程序 ID |
| `@net_revamped_option_names` | 該背景程序每次讀取的選項名稱 |
| `@net_revamped_<key>`、`_ts`、`_lock` | 快取的值、其時間戳記和更新鎖，包括上一次的位元組計數器 |

## 按鍵綁定

| 按鍵 | 動作 | 預設 |
|:-----|:-----|:-----|
| `prefix + M-e` | 顯示所有數據的詳情彈出視窗；按 Enter 關閉 | 已綁定 |

`@net_revamped_popup_key` 可以指定其他按鍵，設為 `off` 則不綁定。預設按鍵已被佔用時不會改動它，`network-revamped doctor` 會說明這一點。

<a id="運作原理"></a>

## 運作原理

tmux 載入插件時，[`network-revamped.tmux`](network-revamped.tmux) 會執行一次。它將 `status-left` 和 `status-right` 用到的指標記錄到 `@net_revamped_published`，然後將每個佔位符替換為對 [`bin/network-revamped`](bin/network-revamped) 的呼叫；在 `options` 模式下則替換為讀取選項，並啟動背景程序。

預設模式下，每個 `#()` 呼叫會即時傳回快取的值。快取超過其間隔時，呼叫會取得鎖並在背景開始更新，因此同一時間只有一個更新在執行。速率等於介面位元組計數器的變化量除以經過的毫秒數。上一次的計數器存放在 tmux 選項中，因此不會寫入任何檔案。

SSID、VPN 名稱、VPN 介面和區域網絡地址在進入狀態列之前，其中每個 `#` 都會加倍，所以名為 `#(cmd)` 的網絡只會顯示為文字，不會被執行。

讀取各工具輸出、取樣和格式化的程式碼位於 [`lib/network.sh`](lib/network.sh)，設定表位於 [`lib/state.sh`](lib/state.sh)。只有狀態列用到的佔位符才會執行對應的探測。時鐘透過 `date` 精確至毫秒，`date` 做不到時改用 perl。

<a id="畫面"></a>

## 畫面

<details>
<summary>所有畫面，在真實的 tmux 中以 <code>make screens</code> 錄製，每個按鍵顯示在狀態列上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/speed.png" alt="network-revamped：按級別著色的速率，以及狀態列中的各項探測"><br><sub>按級別著色的速率，以及狀態列中的各項探測，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="network-revamped：prefix M-e 開啟詳情彈出視窗"><br><sub><code>prefix M-e</code> 開啟詳情彈出視窗，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="network-revamped：將 @net_revamped_icons 設為 nerd，每個指標前都有圖示"><br><sub>將 <code>@net_revamped_icons</code> 設為 <code>nerd</code>，每個指標前都有圖示，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/options.png" alt="network-revamped：在 options 繪製模式下，每個佔位符讀取一個 tmux 選項"><br><sub>在 <code>options</code> 繪製模式下，每個佔位符讀取一個 tmux 選項，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="network-revamped：card 列印所有數據"><br><sub><code>card</code> 列印所有數據，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/precision.png" alt="network-revamped：@net_revamped_precision 設定速率的小數位數"><br><sub><code>@net_revamped_precision</code> 設定速率的小數位數，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="network-revamped：@net_revamped_speed_format 設定速度的格式"><br><sub><code>@net_revamped_speed_format</code> 設定速度的格式，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="network-revamped：@net_revamped_fixed_width 將每個值補齊至最闊的形式"><br><sub><code>@net_revamped_fixed_width</code> 將每個值補齊至最闊的形式，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="network-revamped：為單一指標加上自己的標籤"><br><sub>為單一指標加上自己的標籤，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="network-revamped：list 列印所有綁定"><br><sub><code>list</code> 列印所有綁定，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="network-revamped：status speed 列印上下行速率"><br><sub><code>status speed</code> 列印上下行速率，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="network-revamped：doctor"><br><sub><code>doctor</code>，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="network-revamped：沒有 gum 時的選單"><br><sub>沒有 gum 時的選單，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="network-revamped：從選單執行 doctor"><br><sub>從選單執行 <code>doctor</code>，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="network-revamped：版本"><br><sub>版本，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="network-revamped：不明命令"><br><sub>不明命令，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="network-revamped：來自 NETWORK_REVAMPED_ACCENT 的強調色"><br><sub>來自 <code>NETWORK_REVAMPED_ACCENT</code> 的強調色，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="network-revamped：六種主題下的標題"><br><sub>六種主題下的標題，來自 <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="network-revamped：說明頁"><br><sub>說明頁，來自 <code>help.tape</code></sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

錄製時執行的是真實的插件和 tmux。網絡工具由小腳本代替，所以畫面上的速率和地址來自這些腳本。

</details>

## 可攜性

插件是 POSIX `sh`。CI 在下列每一行上執行全部測試。

| Shell | 狀態 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x、系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用內建的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make fmt` | 對每個腳本執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零警告 |
| `make test` | 在系統 `sh` 下執行 bats 測試 |
| `make test-all` | 在每個已安裝的 shell 下執行測試，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行測試 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後以 100% 為門檻 |
| `make screens` | 以 VHS 在 tmux 中從真實插件錄製上述畫面，在 macOS 上執行 |
| `make install` | 把指令、man 手冊和自動完成安裝到 `PREFIX` 下 |

在 macOS 上，執行 `brew bundle` 會根據 [`Brewfile`](Brewfile) 安裝這些目標用到的所有工具。

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 會執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈新版本，更新版本常數，並把說明寫入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | **本插件**，在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
