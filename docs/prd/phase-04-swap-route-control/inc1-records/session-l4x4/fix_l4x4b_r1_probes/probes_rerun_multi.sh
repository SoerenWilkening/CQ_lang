#!/bin/bash
# probes_rerun_multi.sh <dir-with-*_caller.c> — the TWO-TU probes, FROZEN chk vs fix.
set -u
LLVM=/usr/local/opt/llvm@19/bin
INC=/Users/sorenwilkening/Desktop/CQ_l4x4/include
LIB=/Users/sorenwilkening/Desktop/CQ_l4x4/docs/prd/phase-04-swap-route-control/inc1-records/session-l4x4/probes/impl/multi/w2_lib.c
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4_fix
D="$1"; T=$(mktemp -d); moved=0; n=0
run() {
  out=$("$S/bin/cq-opt.$1" -load-pass-plugin "$S/bin/libCQPass.so.$1" \
        -passes=cq-lowering -S "$2" -o "$T/$1.s2.ll" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then echo "rc1:$(echo "$out" | grep -o 'lowering: .*' | head -1 | sed 's/lowering: //; s/ under quantum control.*//')"
  else echo "rc0:$(md5 -q "$T/$1.s2.ll")"; fi
}
for f in "$D"/*_caller.c; do
  [ -e "$f" ] || continue
  b=$(basename "$f" _caller.c)
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -c "$f"   -o "$T/$b.a.bc" 2>/dev/null || continue
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -c "$LIB" -o "$T/$b.b.bc" 2>/dev/null || continue
  "$LLVM/llvm-link" "$T/$b.a.bc" "$T/$b.b.bc" -S -o "$T/$b.s1.ll" 2>/dev/null || continue
  n=$((n+1)); a=$(run 267937d "$T/$b.s1.ll"); c=$(run fix "$T/$b.s1.ll")
  [ "$a" != "$c" ] && { moved=$((moved+1)); printf 'MOVED %-24s chk=%s -> fix=%s\n' "$b" "$a" "$c"; }
done
echo "[$D] multi-probes=$n MOVED=$moved"
rm -rf "$T"
