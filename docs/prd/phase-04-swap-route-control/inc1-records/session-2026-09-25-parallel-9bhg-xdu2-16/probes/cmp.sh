#!/bin/bash
# cmp.sh a b probe...: diff <probe>.<a>.s2.ll vs <probe>.<b>.s2.ll
cd "$(dirname "$0")"
A=$1; B=$2; shift 2
for m in "$@"; do
  if cmp -s "$m.$A.s2.ll" "$m.$B.s2.ll"; then
    echo "$m: IDENTICAL ($A vs $B)"
  else
    echo "$m: DIFFERS ($A vs $B): $(diff "$m.$A.s2.ll" "$m.$B.s2.ll" | grep -c '^[<>]') lines"
  fi
done
