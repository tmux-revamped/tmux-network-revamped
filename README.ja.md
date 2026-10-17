<div align="center">

# tmux-network-revamped

<strong>ネットワークのスループットをステータスバーに表示し、描画を止めません。</strong>

[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-network-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.4.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">機能</a> |
  <a href="#installation">インストール</a> |
  <a href="#usage">使い方</a> |
  <a href="#configuration">設定</a> |
  <a href="#key-bindings">キーバインド</a> |
  <a href="#how-it-works">仕組み</a>
</p>

</div>

**14** 個のプレースホルダー、**2** つの描画モード、macOS と Linux、tmux **3.2** 以降に対応します。

---

<a id="what-it-does"></a>

## 機能

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

<a id="requirements"></a>

## 動作要件

| 要件 | バージョン |
|:-----|:-----------|
| tmux | 3.2 以降 |
| bash | 3.2 以降 |
| curl | 任意のバージョン、`#{net_public_ip}` と `#{net_online}` に使用 |

Linux と macOS で、BSD、GNU、uutils のいずれの coreutils でも動作します。各プローブは OS に付属するツールを使います。

| データ | macOS | Linux |
|:-------|:------|:------|
| バイトカウンター | `netstat -ib` | `/proc/net/dev` |
| デフォルトのインターフェース | `route -n get default` | `ip route show default` |
| LAN アドレス | `ipconfig getifaddr` | `ip addr show` |
| VPN インターフェース | `netstat -rn` | `ip -o link show up` |
| VPN 名 | `scutil --nc list` | `nmcli` |
| Wi-Fi の信号と名前 | `system_profiler SPAirPortDataType` | `/proc/net/wireless`、`iwgetid` または `iw` |
| 接続数 | `netstat -an` | `netstat -an` |

ツールがない場合、そのプレースホルダーは空になります。

<a id="installation"></a>

## インストール

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

<a id="usage"></a>

## 使い方

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

`@net_revamped_<metric>_label` は、値が空でないときだけ、その指標の前にアイコンや単語を表示します。`@net_revamped_icons` を `nerd` にすると、すべての指標に Nerd Font のグリフが付きます。指標ごとのラベルはこのセットより優先され、空のラベルを設定するとその指標のラベルは消えます。既定値の `ascii` ではラベルは付きません。

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

<a id="configuration"></a>

## 設定

### 計測

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@net_revamped_interface` | 空 | 計測するインターフェース。空ならデフォルトルートのインターフェースを使います |
| `@net_revamped_interval` | `2` | 速度を計測する間隔の秒数 |
| `@net_revamped_precision` | `1` | 速度の小数点以下の桁数。`0` から `9`。丸めて 1000 以上になると、GB/s まで単位を 1 つ上げます |
| `@net_revamped_smoothing` | `0` | 移動平均で前回の速度に与える重みのパーセント。`1` から `99`。`0` なら各計測値をそのまま表示します |
| `@net_revamped_render` | 空 | `options` にすると `#()` を実行せず、公開されたオプションを読み取ります |

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

<a id="key-bindings"></a>

## キーバインド

このプラグインはキーを割り当てません。

<a id="how-it-works"></a>

## 仕組み

tmux がプラグインを読み込むと、[`network-revamped.tmux`](network-revamped.tmux) が 1 回実行されます。`status-left` と `status-right` が使う指標を `@net_revamped_published` に記録し、各プレースホルダーを [`src/network.sh`](src/network.sh) の呼び出しに置き換えます。`options` モードでは、オプションの読み取りに置き換えてバックグラウンドプロセスを起動します。

既定のモードでは、各 `#()` の呼び出しはキャッシュした値をすぐに返します。キャッシュが間隔より古ければ、ロックを取ってバックグラウンドで更新を始めるため、同時に動く更新は 1 つだけです。速度は、インターフェースのバイトカウンターの変化量を経過ミリ秒数で割って求めます。前回のカウンターは tmux のオプションに保存するので、ファイルは書き込みません。

SSID、VPN 名、VPN インターフェース、LAN アドレスの値は、ステータスラインに渡す前にすべての `#` を二重にします。そのため、`#(cmd)` という名前のネットワークもコマンドとして実行されず、文字列として表示されます。

各ツールの出力を解析する処理は [`src/lib/network/network.sh`](src/lib/network/network.sh) に、整形は [`src/lib/network/render.sh`](src/lib/network/render.sh) にあります。

<a id="development"></a>

## 開発

| コマンド | 内容 |
|:---------|:-----|
| `make test` | bats のテストスイートを実行します |
| `make lint` | すべてのシェルファイルに shellcheck を実行します |
| `make coverage` | Linux で kcov を使って行カバレッジを測定し、95% 未満なら失敗します |

変更点は [CHANGELOG.md](CHANGELOG.md) にあります。

<a id="license"></a>

## ライセンス

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約、`family/` 配下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧によってバイト単位で同一に保たれています。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep` がその作業を行います。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CI、ファミリーのツールを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

### インストールの確認

全メンバーがディスク上にあれば、1 つのコマンドでメンバー間の衝突を報告できます。

```sh
family/bin/doctor --live
```

各メンバーと実行中の tmux サーバーを読み取り、重複したキー、重複したステータスのプレースホルダー、命名規則に合わないオプション、規約のバージョンが古いメンバーを報告します。

<!-- family:end -->
