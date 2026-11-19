#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/network_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/network_helpers.bash"

logged() {
  grep -qxF -- "$1" "${FAKE}/log"
}

other_owner() {
  quiet sleep 'kept=$(grep -v "^@net_revamped_ticker_pid	" "'"${FAKE}"'/vars" || :)
printf "%s\n@net_revamped_ticker_pid\tsomeone-else\n" "${kept}" | grep -v "^$" >"'"${FAKE}"'/vars.next"
mv -f "'"${FAKE}"'/vars.next" "'"${FAKE}"'/vars"'
}

settled() {
  local tries=0
  until "$@"; do
    tries=$((tries + 1))
    [[ "${tries}" -lt 200 ]] || return 1
    /bin/sleep 0.05
  done
}

wired() {
  ip_says route 'default via 192.168.0.1 dev eth0 proto dhcp'
  counters_linux eth0 5204800 3051200
}

@test "plan - a fresh install binds the detail popup to M-e" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Network details M-e run-shell ${tool} popup" ]]
}

@test "plan - a key set to off binds nothing, and a key the person names is bound whoever holds it" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  planned
  [[ -z "${output}" ]]
  printf 'bind-key    -T prefix F8     display-message mine\n' >"${FAKE}/keys"
  option popup_key F8

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Network details F8 run-shell ${tool} popup" ]]
}

@test "plan - a tmux older than 3.1 gets its key without a note" {
  # Arrange
  tmux_is 3.0

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key M-e run-shell "*" popup" ]]
}

@test "plan - the default key is left alone when something else holds it, and bound again when the binding is the plugin's own" {
  # Arrange
  printf 'bind-key    -T prefix M-e     display-message mine\n' >"${FAKE}/keys"
  planned 'network_revamped_plan; printf "[%s]\n" "${NETWORK_REVAMPED_SKIPPED}"; '
  [[ "${output}" == "[M-e]" ]]
  printf 'bind-key -r -T prefix M-e     run-shell "/old/bin/network-revamped popup"\n' >"${FAKE}/keys"

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Network details M-e run-shell "*" popup" ]]
}

@test "plan - each placeholder becomes a job that prints it, and the metrics in use are recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{net_fg_color}#{net_speed}#[default] #{net_vpn_name} #{net_vpn}'
  var status-left '#{net_ip} #S'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-left #(${tool} status ip) #S" ]]
  [[ "${lines[1]}" == "set-option -gq status-right #(${tool} status fg_color)#(${tool} status speed)#[default] #(${tool} status vpn_name) #(${tool} status vpn)" ]]
  [[ "${lines[2]}" == "set-option -gq @net_revamped_published speed fg_color vpn vpn_name ip" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "plan - every placeholder has its job" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{net_download}#{net_upload}#{net_bg_color}#{net_wifi}#{net_ssid}#{net_connections}#{net_ping}#{net_public_ip}#{net_online}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status download)#(${tool} status upload)#(${tool} status bg_color)#(${tool} status wifi)#(${tool} status ssid)#(${tool} status connections)#(${tool} status ping)#(${tool} status public_ip)#(${tool} status online)" ]]
  [[ "${lines[1]}" == "set-option -gq @net_revamped_published download upload bg_color wifi ssid connections ping public_ip online" ]]
}

@test "plan - a status line that ends in a semicolon keeps it, escaped, so tmux does not read it as a separator" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{net_speed};'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status speed)\\;" ]]
}

@test "plan - in options mode each placeholder becomes a read of the option the daemon fills" {
  # Arrange
  option popup_key off
  option render options
  var status-right '#{net_fg_color}#{net_speed} | #{net_ip}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #{E:@net_revamped_out_fg_color}#{E:@net_revamped_out_speed} | #{E:@net_revamped_out_ip}" ]]
  [[ "${lines[1]}" == "set-option -gq @net_revamped_published speed fg_color ip" ]]
}

@test "plan - a status line already rewritten is left as it is, and its metrics stay recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option render options
  option published "speed ip"
  var status-right '#{E:@net_revamped_out_speed} | #{E:@net_revamped_out_ip}'
  planned
  [[ -z "${output}" ]]
  option render jobs
  option published "vpn vpn_name"
  var status-right "#(${tool} status vpn_name) #(${tool} status vpn)"

  # Act
  planned

  # Assert
  [[ -z "${output}" ]]
}

@test "plan - a status line with no placeholder is not written, and an old list of metrics is emptied" {
  # Arrange
  option popup_key off
  option published "speed"
  var status-right '%H:%M #{session_name}'

  # Act
  planned

  # Assert
  [[ "${output}" == 'set-option -gq @net_revamped_published ""' ]]
}

@test "plan - a setting given in the environment rides on the key and on every job" {
  # Arrange
  var status-right '#{net_speed}'

  # Act
  planned 'export NETWORK_REVAMPED_PRECISION=2; '

  # Assert
  [[ "${lines[0]}" == *"network-revamped' --precision '2' popup" ]]
  [[ "${lines[1]}" == *"network-revamped' --precision '2' status speed)" ]]
}

@test "plan - settings given in the environment ride in the order of the settings table, and an empty one rides too" {
  # Arrange
  var status-right '#{net_speed}'

  # Act
  planned 'export NETWORK_REVAMPED_HIGH_THRESH=500 NETWORK_REVAMPED_UPLOAD_LABEL= NETWORK_REVAMPED_INTERVAL=3 NETWORK_REVAMPED_POPUP_KEY=F8; '

  # Assert
  [[ "${lines[0]}" == "bind-key -N Network details F8 run-shell "*"network-revamped' --interval '3' --upload-label '' --high-thresh '500' popup" ]]
}

@test "plan - apply sends everything in one tmux call and clears a daemon's claim in jobs mode" {
  # Arrange
  var status-right '#{net_speed}'

  # Act
  lib_run network 'network_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "bind-key -N Network details M-e run-shell "*" popup ; set-option -gq status-right #("*" status speed) ; set-option -gq @net_revamped_published speed" ]]
  [[ "${lines[1]}" == "set-option -gqu @net_revamped_ticker_pid" ]]
}

@test "plan - when tmux refuses the batch each command is sent alone, and the bad one fails the run" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key F99
  var status-right '#{net_speed}'
  printf '%s\n' "bind-key -N Network details F99 run-shell ${tool} popup" >"${FAKE}/refused"

  # Act
  lib_run network 'network_revamped_apply'

  # Assert
  [[ "${status}" -eq 1 ]]
  run sent '^set-option -gq status-right #(.* status speed)$'
  [[ "${output}" == "1" ]]
  holds published speed
}

@test "plan - in options mode apply starts the daemon, which claims the ticker and publishes until another takes over" {
  # Arrange
  wired
  option popup_key off
  option render options
  option interval 1
  var status-right '#{net_speed}'
  other_owner

  # Act
  lib_run network 'network_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  settled holds out_speed "0B/s 0B/s"
  settled holds ticker_pid someone-else
  run sent '^set-option -gq @net_revamped_ticker_pid [0-9][0-9]*$'
  [[ "${output}" == "1" ]]
}

@test "plan - the daemon ends when another process owns the ticker" {
  # Arrange
  wired
  option published "download"
  other_owner

  # Act
  tool daemon

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_download "0B/s"
  holds ticker_pid someone-else
}

@test "plan - the popup runs the card and waits for Enter, in a command that holds no hash" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  lib_run network 'network_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-popup -E -w 70% -h 80% ${tool} card; printf '\\nPress Enter to close. '; read -r network_revamped_wait"
}

@test "plan - the popup carries a setting given in the environment" {
  # Arrange
  export NETWORK_REVAMPED_PRECISION=2

  # Act
  lib_run network 'network_revamped_popup'

  # Assert
  run sent "^display-popup .*network-revamped' --precision '2' card; "
  [[ "${output}" == "1" ]]
}

@test "plan - on a tmux older than 3.2 the popup key says why it opens nothing" {
  # Arrange
  tmux_is 3.1

  # Act
  lib_run network 'network_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "the popup needs tmux 3.2 or later"
  run sent '^display-popup'
  [[ "${output}" == "0" ]]
}

@test "plan - a popup tmux refuses to open leaves the key quiet" {
  # Arrange
  local tool
  tool=$(tool_path)
  printf '%s\n' "display-popup -E -w 70% -h 80% ${tool} card; printf '\\nPress Enter to close. '; read -r network_revamped_wait" >"${FAKE}/refused"

  # Act
  lib_run network 'network_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "plan - a path is quoted for a job with each hash and each percent sign doubled, and for a key with none left" {
  # Arrange
  local script='network_revamped_job_quote "/a b/it'"'"'s#1 50%"; network_revamped_literal "/a b/it'"'"'s#1 50%"'

  # Act
  lib_run network "${script}"

  # Assert
  [[ "${lines[0]}" == "'/a b/it'\\''s##1 50%%'" ]]
  [[ "${lines[1]}" == "'/a b/it'\\''s'\"\$(printf '%b' '\\0043')\"'1 50%'" ]]
}
