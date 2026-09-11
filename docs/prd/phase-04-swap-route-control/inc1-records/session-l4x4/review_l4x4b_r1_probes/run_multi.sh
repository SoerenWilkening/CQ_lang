#!/bin/bash
# run_multi.sh — the TWO-TU round-2 taint-window probes (multi/), all three binaries.
# Each links <name>_caller.c with the shipped 6.5 lib body and lowers the linked module.
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
INC=/Users/sorenwilkening/Desktop/CQ_l4x4/include
LIB=/Users/sorenwilkening/Desktop/CQ_l4x4/docs/prd/phase-04-swap-route-control/inc1-records/session-l4x4/probes/impl/multi/w2_lib.c
T=$(mktemp -d)
for f in "$HERE"/multi/*_caller.c; do
  n=$(basename "$f" _caller.c)
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -c "$f"   -o "$T/$n.a.bc" || continue
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -c "$LIB" -o "$T/$n.b.bc" || continue
  "$LLVM/llvm-link" "$T/$n.a.bc" "$T/$n.b.bc" -S -o "$T/$n.s1.ll" || continue
  line="$n"
  for k in oracle:/Users/sorenwilkening/Desktop/CQ_lang f2:/Users/sorenwilkening/Desktop/CQ_f2 subj:/Users/sorenwilkening/Desktop/CQ_l4x4; do
    key=${k%%:*}; B=${k#*:}
    out=$("$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" \
          -passes=cq-lowering -S "$T/$n.s1.ll" -o /dev/null 2>&1); rc=$?
    if [ $rc -eq 0 ]; then line="$line | $key=rc0"
    else line="$line | $key=$(echo "$out" | grep -o 'lowering: .*' | head -1 | sed 's/lowering: //; s/ under quantum control//')"; fi
  done
  echo "$line"
done
rm -rf "$T"
