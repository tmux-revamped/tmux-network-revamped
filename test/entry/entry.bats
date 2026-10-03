#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

ENTRY="${BATS_TEST_DIRNAME}/../../network-revamped.tmux"

setup() {
  setup_test_environment
  export SPAWN_LOG="${TEST_TMPDIR}/spawn.log"
  nohup() { printf '%s\n' "$*" >> "${SPAWN_LOG}"; }
  export -f nohup
}

teardown() {
  cleanup_test_environment
}

@test "entry - jobs mode turns a placeholder into a dispatcher call" {
  tmux set-option -gq "status-right" "[#{net_download}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#($(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/src/network.sh download)]" ]]
}

@test "entry - options mode turns a placeholder into an option read" {
  tmux set-option -gq "@net_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{net_download}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#{E:@net_revamped_out_download}]" ]]
}

@test "entry - options mode starts the ticker" {
  tmux set-option -gq "@net_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{net_download}]"

  bash "${ENTRY}"

  [[ "$(cat "${SPAWN_LOG}")" == *"/src/network.sh daemon" ]]
}

@test "entry - jobs mode starts no ticker" {
  tmux set-option -gq "status-right" "[#{net_download}]"

  bash "${ENTRY}"

  [ ! -f "${SPAWN_LOG}" ]
}

@test "entry - only metrics on the status line are published" {
  tmux set-option -gq "status-right" "#{net_download}"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @net_revamped_published)")" == "download" ]]
}

@test "entry - a second run keeps metrics already turned into option reads" {
  tmux set-option -gq "@net_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{E:@net_revamped_out_download}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @net_revamped_published)")" == "download" ]]
}
