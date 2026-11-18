#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

loaded_with_status() {
  tmux set-option -g status-right '#{net_speed} end'
  load_plugin
  wait_for host_shows "100.0KB/s 25.0KB/s end"
}

@test "keys - prefix M-e opens the card in a popup, with every reading it has" {
  # Arrange
  loaded_with_status

  # Act
  press C-b M-e

  # Assert
  wait_for host_shows "Press Enter to close."
  host_shows "Interface"
  host_shows "test0"
  host_shows "100.0KB/s"
  host_shows "10.0.0.7"
  host_shows "Cafe #S"
  host_shows "-52 dBm"
  host_shows "Read. test0 is the measured interface."
}

@test "keys - Enter closes the popup and leaves the status line running" {
  # Arrange
  loaded_with_status
  press C-b M-e
  wait_for host_shows "Press Enter to close."

  # Act
  press Enter

  # Assert
  wait_for host_lacks "Press Enter to close."
  wait_for host_shows "100.0KB/s 25.0KB/s end"
}

@test "keys - a key the person names opens the popup, and the default one then does nothing" {
  # Arrange
  setting popup_key F8
  loaded_with_status
  press C-b M-e
  host_lacks "Press Enter to close."

  # Act
  press C-b F8

  # Assert
  wait_for host_shows "Press Enter to close."
}

@test "keys - in options mode the status line reads options a daemon fills" {
  # Arrange
  setting render options
  tmux set-option -g status-right '#{net_speed} | #{net_ip} end'

  # Act
  load_plugin

  # Assert
  run tmux show-option -gqv status-right
  [[ "${output}" == "#{E:@net_revamped_out_speed} | #{E:@net_revamped_out_ip} end" ]]
  wait_for host_shows "100.0KB/s 25.0KB/s | 10.0.0.7 end"
  run tmux show-option -gqv @net_revamped_ticker_pid
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "keys - in options mode the popup key still opens the card" {
  # Arrange
  setting render options
  tmux set-option -g status-right '#{net_speed} end'
  load_plugin
  wait_for host_shows "100.0KB/s 25.0KB/s end"

  # Act
  press C-b M-e

  # Assert
  wait_for host_shows "Press Enter to close."
  host_shows "10.0.0.7"
}
