#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  local name
  for name in $(compgen -v NETWORK_REVAMPED_); do
    unset "${name}"
  done
  unset KODOUGU_THEME KODOUGU_ACCENT NO_COLOR
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${BATS_TEST_TMPDIR}/stubs"
  export REVAMPED_TEST_TMUX_VERSION=3.8
}

transcript() {
  local flow="$1"
  shift
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/network-revamped" "$@"
  TRANSCRIPT="$(printf '$ network-revamped%s\n%s\nexit %s\n' "${*:+ $*}" "${output}" "${status}" | steady)"
  local system
  system="$(/usr/bin/uname -s)"
  case "${system}" in
  Darwin) system=darwin ;;
  *) system=linux ;;
  esac
  GOLDEN="${REVAMPED_TESTS_DIR}/golden/${flow}.${system}.txt"
  if [[ -n "${REVAMPED_TEST_RECORD:-}" ]]; then
    printf '%s\n' "${TRANSCRIPT}" >"${GOLDEN}"
  fi
}

steady() {
  sed -E \
    -e 's#/[^ ,]+#<path>#g' \
    -e 's/(gnu|bsd|uutils|busybox|mawk)( [0-9][0-9.]*)?$/<flavor>/' \
    -e 's/^network-revamped [0-9]+\.[0-9]+\.[0-9]+$/network-revamped <version>/'
}

@test "golden - help" {
  # Arrange
  local flow=help

  # Act
  transcript "${flow}" help

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - version" {
  # Arrange
  local flow=version

  # Act
  transcript "${flow}" version

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - doctor" {
  # Arrange
  local flow=doctor
  harness_hide route ip netstat ipconfig scutil system_profiler nmcli iwgetid iw ping curl ss perl
  cat >"${BATS_TEST_TMPDIR}/stubs/date" <<STUB
#!/bin/sh
{ set +x; } 2>/dev/null
if [ "\${1:-}" = +%s%N ]; then
  printf '1700000123456789012\n'
  exit 0
fi
exec "${BATS_TEST_TMPDIR}/farm/date" "\$@"
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/date"

  # Act
  transcript "${flow}" doctor

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - an unknown command" {
  # Arrange
  local flow=unknown-command

  # Act
  transcript "${flow}" frobnicate

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - an unknown option" {
  # Arrange
  local flow=unknown-option

  # Act
  transcript "${flow}" --frobnicate

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - a bare run without a terminal" {
  # Arrange
  local flow=no-terminal

  # Act
  transcript "${flow}"

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}
