#!/bin/bash
# Run one .ll probe on the ORACLE and on the MERGED binary; print exit + first
# diagnostic line for each.  Usage: xrun.sh <probe.ll> [label]
ORA=/Users/sorenwilkening/Desktop/CQ_lang/build
MRG=/Users/sorenwilkening/Desktop/CQ_merge/build
P="$1"; L="${2:-$(basename "$P")}"
run() { # $1=build dir
  local out err ec
  err=$("$1/ir-pass/cq-opt" -load-pass-plugin "$1/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$P" -o /dev/null 2>&1); ec=$?
  local first=$(printf '%s' "$err" | grep -m1 -oE 'cq [a-z0-9 -]*(lowering|escape|detect)?[^\n]*' | head -c 160)
  [ -z "$first" ] && first=$(printf '%s' "$err" | head -1 | head -c 160)
  if [ $ec -eq 0 ]; then echo "ACCEPT(exit 0)"; else echo "DECLINE(exit $ec): $first"; fi
}
printf "%-52s ORACLE: %s\n" "$L" "$(run $ORA)"
printf "%-52s MERGED: %s\n" "$L" "$(run $MRG)"
