#!/bin/sh

network_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${network_revamped_dir}/bin/network-revamped" apply
