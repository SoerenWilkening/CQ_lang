#!/bin/bash
# run.sh [oracle|f2|subj] — lower every single-TU probe beside this file with the
# named binary and print `rc` + the diagnostic (or the emitted gate stream).
#   oracle = main 0c7380c   f2 = the Track-C base 578dbc4   subj = l4x4b (default)
# All three binaries are read-only; nothing here rebuilds.
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
KEY="${1:-subj}"
case "$KEY" in
  subj)   B=/Users/sorenwilkening/Desktop/CQ_l4x4 ;;
  oracle) B=/Users/sorenwilkening/Desktop/CQ_lang ;;
  f2)     B=/Users/sorenwilkening/Desktop/CQ_f2 ;;
  *) echo "usage: $0 [oracle|f2|subj]"; exit 2 ;;
esac
INC=/Users/sorenwilkening/Desktop/CQ_l4x4/include
T=$(mktemp -d)
for f in "$HERE"/*.c; do
  n=$(basename "$f" .c)
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/$n.s1.ll" 2>/dev/null || { printf '%-26s CLANG-FAIL\n' "$n"; continue; }
  out=$("$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$T/$n.s1.ll" -o "$T/$n.s2.ll" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    printf '%-26s rc=1 %s\n' "$n" "$(echo "$out" | grep -o 'lowering: .*' | head -1 | sed 's/lowering: //; s/ under quantum control//')"
  else
    printf '%-26s rc=0 %s\n' "$n" \
      "$(awk '/^define /,/^}/' "$T/$n.s2.ll" | grep -oE '@(cqrt|cq_template)[A-Za-z0-9_]*\(' | tr -d '@(' | head -14 | tr '\n' ' ')"
  fi
done
rm -rf "$T"
