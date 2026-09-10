#!/bin/bash
# run_multi.sh [PRE|PREB1|POST] [filter] — the TWO-TU probes (the shipped 6.5
# recipe: per-TU -O1 IR, llvm-link, ONE cq-lowering pass). Each probe is a pair
# multi/<n>_caller.c + multi/<n>_lib.c.
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=${CQ_ROOT:-/Users/sorenwilkening/Desktop/CQ_lang}
HERE=$(cd "$(dirname "$0")" && pwd)
SCR=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad
w=${1:-POST}; filt=${2:-}
case "$w" in
  PRE)   O="$SCR/fix_r2/pre/cq-opt";  P="$SCR/fix_r2/pre/libCQPass.so" ;;
  PREB1) O="$SCR/impl_b1/pre/cq-opt"; P="$SCR/impl_b1/pre/libCQPass.so" ;;
  *)     O="$ROOT/build/ir-pass/cq-opt"; P="$ROOT/build/ir-pass/libCQPass.so" ;;
esac
OUT="$HERE/out/multi-$w"; mkdir -p "$OUT"
for cf in "$HERE"/multi/*_caller.c; do
  [ -e "$cf" ] || continue
  n=$(basename "$cf" _caller.c)
  if [ -n "$filt" ]; then case "$n" in $filt) ;; *) continue;; esac; fi
  "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -emit-llvm -S "$cf" -o "$OUT/$n.c.ll" 2>/dev/null
  "$LLVM/clang" -O1 -emit-llvm -S "$HERE/multi/${n}_lib.c" -o "$OUT/$n.l.ll" 2>/dev/null
  "$LLVM/llvm-link" -S "$OUT/$n.c.ll" "$OUT/$n.l.ll" -o "$OUT/$n.s1.ll"
  "$O" -load-pass-plugin "$P" -passes=cq-lowering -S "$OUT/$n.s1.ll" -o "$OUT/$n.s2.ll" 2>"$OUT/$n.err"; rc=$?
  if [ $rc -ne 0 ]; then echo "$n rc=$rc DECLINE: $(grep -o 'cq [a-z0-9/ -]*: [^;]*' "$OUT/$n.err" | head -1)"
  else python3 "$ROOT/tools/free_pairing_check.py" "$OUT/$n.s2.ll" > "$OUT/$n.2b" 2>&1
       "$LLVM/clang" "$OUT/$n.s2.ll" "$ROOT/build/runtime/libcq_templates.a" "$ROOT/build/runtime/libcq_runtime.a" -o "$OUT/$n.bin" 2>/dev/null && "$OUT/$n.bin" > "$OUT/$n.trace"
       echo "$n rc=0 ACCEPT trace=$(wc -l < "$OUT/$n.trace" | tr -d ' ') 2b=$(sed -n 's/.*: \([0-9]* verified.*\)/\1/p' "$OUT/$n.2b" | head -1)"
  fi
done
