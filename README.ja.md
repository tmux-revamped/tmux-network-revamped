<div align="center">

# tmux-network-revamped

<strong>ネットワークのスループットをステータスバーに表示し、描画を止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-network-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-network-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-network-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-network-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-network-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-network-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="ステータスラインに通信速度と各プローブを表示し、詳細ポップアップを開き、Nerd Font のラベルと options 描画モードに切り替える network-revamped" width="800">
</p>

```console
$ network-revamped refresh
Refreshed. en0 moves 55.2KB/s down and 18.4KB/s up.
$ network-revamped status speed
55.2KB/s 18.4KB/s
```

**14** 個のプレースホルダー、**2** つの描画モード、macOS と Linux、tmux **3.2** 以降に対応します。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 以降 | ファミリー共通の最低バージョン。ポップアップにも必要です |
| curl | 任意 | `#{net_public_ip}` と `#{net_online}`。なければ到達性の確認は ping で行います |
| gum | 任意 | `network-revamped` のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

Linux と macOS で、BSD、GNU、uutils のいずれの coreutils でも動作します。各プローブは OS に付属するツールを使います。

| データ | macOS | Linux |
|:-------|:------|:------|
| バイトカウンター | `netstat -ib` | `/proc/net/dev` |
| デフォルトのインターフェース | `route -n get default` | `ip route show default` |
| LAN アドレス | `ipconfig getifaddr` | `ip addr show` |
| VPN インターフェース | `netstat -rn` | `ip -o link show up` |
| VPN 名 | `scutil --nc list` | `nmcli` |
| Wi-Fi の信号と名前 | `system_profiler SPAirPortDataType` | `/proc/net/wireless`、`iwgetid` または `iw` |
| 接続数 | `netstat -an` | `netstat -an` または `ss` |

ツールがない場合、そのプレースホルダーは空になります。

### インストール

[TPM](https://github.com/tmux-plugins/tpm) を使う場合は、`~/.tmux.conf` にプラグインを追加して `prefix + I` を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-network-revamped'
```

手動でインストールする場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-network-revamped ~/.tmux/plugins/tmux-network-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-network-revamped/network-revamped.tmux
```

`status-left` または `status-right` はプラグインを読み込む前に設定してください。プラグインは読み込み時に 1 回だけ、そこにあるプレースホルダーを置き換えます。

クローンで `make install` を実行すると、`network-revamped` が `~/.local/bin` に、manページと補完が `~/.local/share` の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-network-revamped/bin/network-revamped doctor
```

## 使い方

ステータスラインにダウンロードとアップロードの速度を表示し、VPN、LAN アドレス、確立済みの接続数、Wi-Fi の信号強度とネットワーク名も表示します。ping の遅延、グローバル IP アドレス、インターネットへの到達性は、それぞれネットワーク通信を伴うため、明示的に有効にした場合だけ動作します。

| プレースホルダー | 出力 |
|:-----------------|:-----|
| `#{net_download}` | ダウンロード速度。例：`1.2MB/s` |
| `#{net_upload}` | アップロード速度。例：`256.0KB/s` |
| `#{net_speed}` | `@net_revamped_speed_format` で整形したダウンロードとアップロード |
| `#{net_fg_color}` | 現在の通信量の段階に対応する前景スタイル |
| `#{net_bg_color}` | 現在の通信量の段階に対応する背景スタイル |
| `#{net_vpn}` | 有効な VPN インターフェース。例：`utun3`、`wg0`。なければ空 |
| `#{net_vpn_name}` | macOS では `scutil`、Linux では `nmcli` から得た VPN 接続名 |
| `#{net_ip}` | デフォルトルートのインターフェースの IPv4 アドレス |
| `#{net_connections}` | 確立済みの接続数 |
| `#{net_ping}` | `8.8.8.8` への遅延。オプトイン |
| `#{net_public_ip}` | グローバル IPv4 アドレス。オプトイン |
| `#{net_wifi}` | Wi-Fi の信号強度。例：`-55dBm` |
| `#{net_ssid}` | 現在の Wi-Fi ネットワーク名 |
| `#{net_online}` | インターネットへの到達性を示す `on` または `off`。オプトイン |

ステータスラインにプレースホルダーを書きます。

```tmux
set -g @net_revamped_low_fg_color '#[fg=green]'
set -g @net_revamped_medium_fg_color '#[fg=yellow]'
set -g @net_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{net_fg_color}#{net_speed}#[default] '
```

同じ例が [examples/status-right.tmux.conf](examples/status-right.tmux.conf) にあります。

ネットワーク通信を伴うプローブを有効にします。

```tmux
set -g @net_revamped_ping_enabled '1'
set -g @net_revamped_public_ip_enabled '1'
set -g @net_revamped_online_enabled '1'
```

### ラベルと幅

`@net_revamped_<metric>_label` は、値が空でないときだけ、その指標の前にアイコンや単語を表示します。`@net_revamped_icons` を `nerd` にすると、すべての指標に Nerd Font のグリフが付きます。指標ごとのラベルはこのセットより優先されます。既定値の `ascii` ではラベルは付きません。

| 指標 | `nerd` のグリフ |
|:-----|:----------------|
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

`@net_revamped_fixed_width` を `on` にすると、各値を左側に空白を入れて最大の長さにそろえます。速度が `5.0KB/s` から `142.0KB/s` に変わっても、行の残りの部分はずれません。この幅は、既定の精度の速度で 9 文字、ping で 5 文字です。`@net_revamped_<metric>_width` は 1 つの指標の幅を設定し、固定幅より優先されます。長い値が切り詰められることはありません。

### 描画モード

既定では、各プレースホルダーは `#()` の呼び出しになり、tmux はステータスの再描画のたびにそれを再実行します。`@net_revamped_render` を `options` にすると、各プレースホルダーは `#{E:@net_revamped_out_download}` のようなオプションの読み取りになります。サーバーごとに 1 つのバックグラウンドプロセスが `@net_revamped_interval` 秒ごとに計測し、すべての値を 1 回の tmux 呼び出しで書き込むため、値はそろって変わります。

```tmux
set -g @net_revamped_render 'options'
set -g @net_revamped_fixed_width 'on'
```

### 段階ごとの色

段階のスタイルは既定では空なので、設定するまで `#{net_fg_color}` と `#{net_bg_color}` は何も出力しません。以下の配色は、通信量の少ない段階を緑、中程度を黄、多い段階を赤に対応させています。

| テーマ | 少 | 中 | 多 |
|:-------|:---|:---|:---|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

各値は `set -g @net_revamped_low_fg_color '#[fg=#a6e3a1]'` のようにスタイルとして指定します。

| コマンド | 動作 |
|:--------|:-------------|
| `network-revamped apply` | ポップアップのキーを割り当て、プレースホルダーを今すぐ置き換えます。プラグインの読み込み時にエントリーポイントが実行します |
| `network-revamped list` | `apply` が送るコマンドをすべて表示し、何も変更しません。`--json` で 1 つのオブジェクトを出力します |
| `network-revamped status NAME` | プレースホルダーを 1 つ出力します。`speed`、`ip`、`ssid` などで、ステータスラインが実行します |
| `network-revamped refresh` | ネットワークを今すぐ計測し、通信速度を表示します |
| `network-revamped card` | すべてを今すぐ読み取り、項目ごとに 1 行で表示します |
| `network-revamped popup` | カードを tmux のポップアップで開きます。ポップアップのキーが実行します |
| `network-revamped daemon` | `options` 描画モードのために、ティックごとにプレースホルダーを公開します。`apply` が起動します |
| `network-revamped doctor` | 依存関係ごとに 1 行。各値の取得元となるツールやファイル、時計の精度、触れなかったキーも含みます |
| `network-revamped version` | バージョンと tmux のバージョン |
| `network-revamped help` | ヘルプ。`man network-revamped` にも同じコマンドと設定があります |
| `network-revamped` | 端末ではメニュー |

## 設定

どのオプションも、ダッシュ区切りのコマンドオプション（例 `--precision 2`）と環境変数（例 `NETWORK_REVAMPED_PRECISION`）で指定できます。優先順位はコマンドライン、環境変数、tmux オプションの順です。空の tmux オプションは既定値を意味します。`doctor` は、プラグインが認識できない値を持つ設定の名前を表示します。`apply` に渡したものは、ポップアップのキーとすべてのステータスの呼び出しに引き継がれます。

### 計測

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@net_revamped_interface` | 空 | 計測するインターフェース。空ならデフォルトルートのインターフェースを使います |
| `@net_revamped_interval` | `2` | 速度を計測する間隔の秒数 |
| `@net_revamped_precision` | `1` | 速度の小数点以下の桁数。`0` から `9`。丸めて 1000 以上になると、TB/s まで単位を 1 つ上げます |
| `@net_revamped_smoothing` | `0` | 移動平均で前回の速度に与える重みのパーセント。`1` から `99`。`0` なら各計測値をそのまま表示します |
| `@net_revamped_render` | `jobs` | `options` にすると `#()` を実行せず、公開されたオプションを読み取ります |

### プローブ

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@net_revamped_ping_enabled` | `0` | `1` で `8.8.8.8` に ping を送ります |
| `@net_revamped_public_ip_enabled` | `0` | `1` で `icanhazip.com` からグローバルアドレスを取得します |
| `@net_revamped_online_enabled` | `0` | `1` で `https://www.gstatic.com/generate_204` にリクエストします。curl がなければ ping を使います |
| `@net_revamped_<probe>_interval` | `30` | 1 つのプローブを実行する間隔の秒数。対象は `vpn`、`vpn_name`、`ip`、`connections`、`wifi`、`ssid`、`online` |
| `@net_revamped_ping_interval` | `15` | ping を送る間隔の秒数 |
| `@net_revamped_public_ip_interval` | `300` | グローバルアドレスを取得する間隔の秒数 |
| `@net_revamped_online_interval` | `30` | 到達性を確認する間隔の秒数 |

### 書式とラベル

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@net_revamped_speed_format` | `%s %s` | ダウンロード、アップロードの順に渡す `printf` の書式 |
| `@net_revamped_ping_format` | `%sms` | 遅延の `printf` の書式 |
| `@net_revamped_wifi_format` | `%sdBm` | 信号強度の `printf` の書式 |
| `@net_revamped_online_up_text` | `on` | 到達できるときの文字列 |
| `@net_revamped_online_down_text` | `off` | 到達できないときの文字列。プローブが有効なときだけ表示します |
| `@net_revamped_icons` | `ascii` | `nerd` で全指標に Nerd Font のグリフを付けます |
| `@net_revamped_<metric>_label` | 空 | 1 つの指標の前に表示するラベル |
| `@net_revamped_fixed_width` | `off` | `on` で全値を最大の長さにそろえます |
| `@net_revamped_<metric>_width` | 空 | 1 つの指標の幅 |

### 通信量の段階

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@net_revamped_medium_thresh` | `100` | 中程度の段階が始まる、ダウンロードとアップロードの合計（KB/s） |
| `@net_revamped_high_thresh` | `1000` | 多い段階が始まる、ダウンロードとアップロードの合計（KB/s） |
| `@net_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 各段階で `#{net_fg_color}` と `#{net_bg_color}` が出力するスタイル |

### 内部状態

以下のオプションはプラグイン自身が書き込みます。設定しないでください。

| オプション | 保持する内容 |
|:-----------|:-------------|
| `@net_revamped_published` | 読み込み時にステータスラインで見つかった指標 |
| `@net_revamped_out_<metric>` | `options` モードでの各指標の描画済みの値 |
| `@net_revamped_ticker_pid` | `options` モードのバックグラウンドプロセスのプロセス ID |
| `@net_revamped_option_names` | そのバックグラウンドプロセスが毎回読み取るオプション名 |
| `@net_revamped_<key>`、`_ts`、`_lock` | キャッシュした値、そのタイムスタンプと更新ロック。前回のバイトカウンターも含みます |

## キーバインド

| キー | 動作 | 既定 |
|:-----|:-----|:-----|
| `prefix + M-e` | すべての値を表示する詳細ポップアップ。Enter で閉じます | 割り当て済み |

`@net_revamped_popup_key` で別のキーを指定でき、`off` にすると割り当てません。既定のキーがすでに他で使われている場合は触れず、`network-revamped doctor` がそれを表示します。

<a id="仕組み"></a>

## 仕組み

tmux がプラグインを読み込むと、[`network-revamped.tmux`](network-revamped.tmux) が 1 回実行されます。`status-left` と `status-right` が使う指標を `@net_revamped_published` に記録し、各プレースホルダーを [`bin/network-revamped`](bin/network-revamped) の呼び出しに置き換えます。`options` モードでは、オプションの読み取りに置き換えてバックグラウンドプロセスを起動します。

既定のモードでは、各 `#()` の呼び出しはキャッシュした値をすぐに返します。キャッシュが間隔より古ければ、ロックを取ってバックグラウンドで更新を始めるため、同時に動く更新は 1 つだけです。速度は、インターフェースのバイトカウンターの変化量を経過ミリ秒数で割って求めます。前回のカウンターは tmux のオプションに保存するので、ファイルは書き込みません。

SSID、VPN 名、VPN インターフェース、LAN アドレスの値は、ステータスラインに渡す前にすべての `#` を二重にします。そのため、`#(cmd)` という名前のネットワークもコマンドとして実行されず、文字列として表示されます。

各ツールの出力の読み取り、計測、整形は [`lib/network.sh`](lib/network.sh) に、設定の表は [`lib/state.sh`](lib/state.sh) にあります。プローブは、ステータスラインが使うプレースホルダーの分だけ実行されます。時計は `date` でミリ秒まで数え、`date` でできない環境では perl を使います。

<a id="画面"></a>

## 画面

<details>
<summary>すべての画面。本物の tmux の中で <code>make screens</code> で録画し、押したキーをステータスラインに表示しています</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/speed.png" alt="network-revamped: 段階ごとに色分けした通信速度と、ステータスラインの各プローブ"><br><sub>段階ごとに色分けした通信速度と、ステータスラインの各プローブ。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="network-revamped: prefix M-e で詳細ポップアップを開く"><br><sub><code>prefix M-e</code> で詳細ポップアップを開く。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="network-revamped: @net_revamped_icons を nerd にすると各指標にグリフが付く"><br><sub><code>@net_revamped_icons</code> を <code>nerd</code> にすると各指標にグリフが付く。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/options.png" alt="network-revamped: options 描画モードでは各プレースホルダーが tmux オプションを読む"><br><sub><code>options</code> 描画モードでは各プレースホルダーが tmux オプションを読む。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="network-revamped: card がすべての値を表示する"><br><sub><code>card</code> がすべての値を表示する。<code>features.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/precision.png" alt="network-revamped: @net_revamped_precision が通信速度の小数点以下の桁数を決める"><br><sub><code>@net_revamped_precision</code> が通信速度の小数点以下の桁数を決める。<code>features.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="network-revamped: @net_revamped_speed_format が速度の書式を決める"><br><sub><code>@net_revamped_speed_format</code> が速度の書式を決める。<code>features.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="network-revamped: @net_revamped_fixed_width が各値を最大幅にそろえる"><br><sub><code>@net_revamped_fixed_width</code> が各値を最大幅にそろえる。<code>features.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="network-revamped: 指標ごとのラベル"><br><sub>指標ごとのラベル。<code>features.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="network-revamped: list がすべての割り当てを表示する"><br><sub><code>list</code> がすべての割り当てを表示する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="network-revamped: status speed が上下の速度を出力する"><br><sub><code>status speed</code> が上下の速度を出力する。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="network-revamped: doctor"><br><sub><code>doctor</code>。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="network-revamped: gum なしのメニュー"><br><sub>gum なしのメニュー。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="network-revamped: メニューからの doctor"><br><sub>メニューからの <code>doctor</code>。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="network-revamped: バージョン"><br><sub>バージョン。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="network-revamped: 不明なコマンド"><br><sub>不明なコマンド。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="network-revamped: NETWORK_REVAMPED_ACCENT によるアクセント"><br><sub><code>NETWORK_REVAMPED_ACCENT</code> によるアクセント。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="network-revamped: 6 つのテーマのヘッダー"><br><sub>6 つのテーマのヘッダー。<code>themes.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="network-revamped: ヘルプ"><br><sub>ヘルプ。<code>help.tape</code>より</sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

録画では本物のプラグインと tmux を動かしています。ネットワークのツールの代わりに小さなスクリプトを使っているため、画面の通信速度やアドレスはそのスクリプトのものです。

</details>

## 移植性

プラグインは POSIX `sh` です。CI は下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOS の `/bin/sh` | 対応 |
| `bash` 3.2 と 5.x、システムの `zsh` と Homebrew の `zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple Silicon と Intel の Tahoe。付属のツール、Homebrew の GNU ツール、Homebrew の uutils で確認 |
| Linux | x86_64 と arm64 の Ubuntu 26.04。GNU coreutils、uutils、BusyBox で確認 |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトに shfmt `-i 2` をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlint を、指摘ゼロで通します |
| `make test` | システムの `sh` で bats のテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu のコンテナでテスト |
| `make coverage` | この Mac と Ubuntu のコンテナで bashcov を実行し、合算して 100 パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインから tmux の中で VHS で録画します。macOS で実行します |
| `make install` | コマンド、manページ、補完を `PREFIX` の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットは Conventional Commits の形式に従い、そのまま `main` に入ります。`main` で `ci` が成功すると、`release.yml` が semantic-release を実行します。前回のタグ以降に `feat` か `fix` があればリリースを公開し、バージョン定数を更新し、変更内容を [`CHANGELOG.md`](CHANGELOG.md) に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | **このプラグイン**、ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
