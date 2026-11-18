#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

everything() {
  local options
  options=$(tmux show-options -g)
  grep -vE '@net_revamped_(download|upload|total|down_smooth|up_smooth|sample_ms|rx_raw|tx_raw|[a-z_]+_ts|download_lock) ' <<<"${options}"
  tmux list-keys
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- network-revamped.tmux bin/network-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading binds the popup on M-e and turns the placeholder into its job, which shows the rates" {
  # Arrange
  local keys
  tmux set-option -g status-right '#{net_speed} end'

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-e' <<<"${keys}"
  [[ "${output}" == "1" ]]
  run tmux show-option -gqv status-right
  [[ "${output}" == "#('${ROOT}/bin/network-revamped' status speed) end" ]]
  wait_for host_shows "100.0KB/s 25.0KB/s end"
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  tmux set-option -g status-right '#{net_speed} end'
  load_plugin
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${before}" == "${after}" ]]
}

@test "entrypoint - a Wi-Fi name that holds a tmux format is shown as text" {
  # Arrange
  tmux set-option -g status-right '#{net_ssid} #{net_wifi} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows "Cafe #S -52dBm end"
}

@test "entrypoint - in the nerd set a label set to nothing on a real server means the default, so every metric keeps its glyph" {
  # Arrange
  tmux set-option -g @net_revamped_icons nerd
  tmux set-option -g @net_revamped_ssid_label ''
  tmux set-option -g status-right '#{net_ssid} #{net_wifi} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows $'\xf3\xb0\x96\xa9 Cafe #S \xf3\xb0\x96\xa9 -52dBm end'
}

@test "entrypoint - a checkout whose path holds a space, a quote and a hash loads, shows the rates and takes its key" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 plug in"
  mkdir -p "${copy}"
  cp -R "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/network-revamped.tmux" "${copy}/"
  tmux set-option -g status-right '#{net_speed} end'
  load_plugin "${copy}"
  wait_for host_shows "100.0KB/s 25.0KB/s end"

  # Act
  press C-b M-e

  # Assert
  wait_for host_shows "Press Enter to close."
  host_shows "test0"
}

@test "entrypoint - a default key someone else holds is left alone, and one the person names is bound" {
  # Arrange
  local table
  tmux bind-key -T prefix M-e display-message taken
  load_plugin
  table=$(tmux list-keys -T prefix)
  run grep -c 'M-e  *display-message taken' <<<"${table}"
  [[ "${output}" == "1" ]]
  run grep -c 'network-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
  tmux bind-key -T prefix x display-message taken-too
  setting popup_key x

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'network-revamped. popup' <<<"${table}"
  [[ "${output}" == "1" ]]
}

@test "entrypoint - a key set to off binds nothing" {
  # Arrange
  local table
  setting popup_key off

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'network-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
}
