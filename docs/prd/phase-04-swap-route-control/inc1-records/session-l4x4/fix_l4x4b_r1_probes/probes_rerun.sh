#!/bin/bash
# probes_rerun.sh <dir> — re-run every single-TU probe in <dir> against the FROZEN
# checkpoint (267937d) and FROZEN fix binaries, and print only the ROWS THAT MOVED.
# Frozen copies, never the live build tree (IMPL_f2 §5b).
set -u
LLVM=/usr/local/opt/llvm@19/bin
INC=/Users/sorenwilkening/Desktop/CQ_l4x4/include
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4_fix
D="$1"; T=$(mktemp -d); moved=0; n=0; fail=0
run() { # $1=tag $2=s1.ll
  out=$("$S/bin/cq-opt.$1" -load-pass-plugin "$S/bin/libCQPass.so.$1" \
        -passes=cq-lowering -S "$2" -o "$T/$1.s2.ll" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    echo "rc1:$(echo "$out" | grep -o 'lowering: .*' | head -1 | sed 's/lowering: //; s/ under quantum control.*//')"
  else
    echo "rc0:$(md5 -q "$T/$1.s2.ll")"
  fi
}
for f in "$D"/*.c; do
  [ -e "$f" ] || continue
  b=$(basename "$f" .c)
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/$b.s1.ll" 2>/dev/null \
    || { printf '%-30s CLANG-FAIL\n' "$b"; fail=$((fail+1)); continue; }
  n=$((n+1))
  a=$(run 267937d "$T/$b.s1.ll"); c=$(run fix "$T/$b.s1.ll")
  if [ "$a" != "$c" ]; then
    moved=$((moved+1)); printf 'MOVED %-30s chk=%s -> fix=%s\n' "$b" "$a" "$c"
  fi
done
echo "[$D] probes=$n clang-fail=$fail MOVED=$moved (rc0 rows compared by lowered-IR md5)"
rm -rf "$T"
