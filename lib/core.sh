#!/bin/sh
# shellcheck disable=SC2034

[ -n "${NETWORK_REVAMPED_CORE_LOADED:-}" ] && return 0
NETWORK_REVAMPED_CORE_LOADED=1

readonly NETWORK_REVAMPED_VERSION="1.5.0"
