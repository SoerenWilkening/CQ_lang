#!/bin/bash
# both.sh "tags" base... : gen+run <base>C and <base>Q variants
TAGS=$1; shift
L=()
for b in "$@"; do L+=("${b}C" "${b}Q"); done
bash "$(dirname "$0")/gen.sh" "${L[@]}" 2>&1 | grep -v warning
bash "$(dirname "$0")/run.sh" "$TAGS" "${L[@]}"
