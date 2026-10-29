<div align="center">

# tmux-network-revamped

<strong>在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文（香港）

[![family](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/family.yml?branch=main&style=flat-square&label=family)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/family.yml)
[![tests](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/tests.yml?branch=main&style=flat-square&label=tests)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-network-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-network-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-network-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-network-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-network-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#installation">安裝</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">設定</a> |
  <a href="#key-bindings">按鍵綁定</a> |
  <a href="#how-it-works">運作原理</a>
</p>

</div>

**14** 個佔位符，**2** 種繪製模式，支援 macOS 和 Linux，需要 tmux **3.2** 或以上版本。

---

<a id="what-it-does"></a>

## 功能

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

<a id="requirements"></a>

## 系統要求

| 要求 | 版本 |
|:-----|:-----|
| tmux | 3.2 或以上 |
| bash | 3.2 或以上 |
| curl | 任何版本，用於 `#{net_public_ip}` 和 `#{net_online}` |

可在 Linux 和 macOS 上執行，支援 BSD、GNU 或 uutils coreutils。每個探測都使用作業系統內置的工具：

| 資料 | macOS | Linux |
|:-----|:------|:------|
| 位元組計數器 | `netstat -ib` | `/proc/net/dev` |
| 預設介面 | `route -n get default` | `ip route show default` |
| 區域網絡地址 | `ipconfig getifaddr` | `ip addr show` |
| VPN 介面 | `netstat -rn` | `ip -o link show up` |
| VPN 名稱 | `scutil --nc list` | `nmcli` |
| Wi-Fi 訊號和名稱 | `system_profiler SPAirPortDataType` | `/proc/net/wireless`、`iwgetid` 或 `iw` |
| 連線數目 | `netstat -an` | `netstat -an` |

缺少某個工具時，相應的佔位符為空。

<a id="installation"></a>

## 安裝

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

<a id="usage"></a>

## 用法

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

`@net_revamped_<metric>_label` 只在值不為空時，於該指標前顯示一個圖示或文字。將 `@net_revamped_icons` 設為 `nerd` 後，每個指標都會加上 Nerd Font 圖示。個別指標的標籤優先於這套圖示，設為空標籤即移除該指標的標籤。預設值 `ascii` 不加任何標籤。

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

<a id="configuration"></a>

## 設定

### 取樣

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@net_revamped_interface` | 空 | 要量度的介面；為空時使用預設路由介面 |
| `@net_revamped_interval` | `2` | 速率取樣的間隔秒數 |
| `@net_revamped_precision` | `1` | 速率的小數位數，`0` 至 `9`；四捨五入後達 1000 或以上時進一個單位，最高至 GB/s |
| `@net_revamped_smoothing` | `0` | 移動平均中上一次速率所佔的百分比權重，`1` 至 `99`；`0` 顯示每次取樣的原值 |
| `@net_revamped_render` | 空 | 設為 `options` 時讀取已發佈的選項，而不執行 `#()` 呼叫 |

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

<a id="key-bindings"></a>

## 按鍵綁定

本插件不綁定任何按鍵。

<a id="how-it-works"></a>

## 運作原理

tmux 載入插件時，[`network-revamped.tmux`](network-revamped.tmux) 會執行一次。它將 `status-left` 和 `status-right` 用到的指標記錄到 `@net_revamped_published`，然後將每個佔位符替換為對 [`src/network.sh`](src/network.sh) 的呼叫；在 `options` 模式下則替換為讀取選項，並啟動背景程序。

預設模式下，每個 `#()` 呼叫會即時傳回快取的值。快取超過其間隔時，呼叫會取得鎖並在背景開始更新，因此同一時間只有一個更新在執行。速率等於介面位元組計數器的變化量除以經過的毫秒數。上一次的計數器存放在 tmux 選項中，因此不會寫入任何檔案。

SSID、VPN 名稱、VPN 介面和區域網絡地址在進入狀態列之前，其中每個 `#` 都會加倍，所以名為 `#(cmd)` 的網絡只會顯示為文字，不會被執行。

解析各工具輸出的程式碼位於 [`src/lib/network/network.sh`](src/lib/network/network.sh)，格式化程式碼位於 [`src/lib/network/render.sh`](src/lib/network/render.sh)。

<a id="development"></a>

## 開發

| 指令 | 作用 |
|:-----|:-----|
| `make test` | 執行 bats 測試套件 |
| `make lint` | 對所有 shell 檔案執行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 量度行覆蓋率，低於 95% 時失敗 |

變更紀錄見 [CHANGELOG.md](CHANGELOG.md)。

<a id="license"></a>

## 授權

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的成員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中的同一份約定、`family/` 下的同一套工具和同一個共用程式庫，並由校驗和清單確保逐位元組一致。這些成員可以一併安裝：任何成員都不會佔用其他成員使用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。這項責任寫在約定之中，而不是依靠記憶，`family/bin/sweep` 負責執行。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的任何衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員和正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
