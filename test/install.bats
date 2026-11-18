#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  ROOT="$(cd "${REVAMPED_TESTS_DIR}/.." && pwd)"
}

complete_words() {
  # shellcheck source=completions/network-revamped.bash
  source "${ROOT}/completions/network-revamped.bash"
  COMP_WORDS=("$@")
  COMP_CWORD=$(($# - 1))
  _network_revamped
  printf '%s\n' "${COMPREPLY[@]}"
}

@test "install - make install puts a working tool, its man page and completions under PREFIX" {
  # Arrange
  local prefix="${BATS_TEST_TMPDIR}/prefix with space"

  # Act
  make -s -C "${ROOT}" install PREFIX="${prefix}"

  # Assert
  run "${prefix}/bin/network-revamped" version
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == network-revamped\ * ]]
  [[ -f "${prefix}/share/man/man1/network-revamped.1" ]]
  [[ -f "${prefix}/share/bash-completion/completions/network-revamped" ]]
  [[ -f "${prefix}/share/zsh/site-functions/_network-revamped" ]]
  [[ -f "${prefix}/share/fish/vendor_completions.d/network-revamped.fish" ]]
}

@test "install - a second install replaces the first" {
  # Arrange
  local prefix="${BATS_TEST_TMPDIR}/prefix"
  make -s -C "${ROOT}" install PREFIX="${prefix}"
  printf 'stale\n' >"${prefix}/share/network-revamped/lib/stale.sh"

  # Act
  make -s -C "${ROOT}" install PREFIX="${prefix}"

  # Assert
  [[ ! -e "${prefix}/share/network-revamped/lib/stale.sh" ]]
  [[ -x "${prefix}/bin/network-revamped" ]]
}

@test "install - bash completes the commands" {
  # Arrange
  local word=d

  # Act
  run complete_words network-revamped "${word}"

  # Assert
  [[ "${output}" == $'daemon\ndoctor' ]]
}

@test "install - bash completes the themes after --theme" {
  # Arrange
  local word=no

  # Act
  run complete_words network-revamped --theme "${word}"

  # Assert
  [[ "${output}" == "nord" ]]
}
