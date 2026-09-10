#!/bin/bash
# run_multi.sh [PRE|POST] — the two TWO-TU probes (the shipped 6.5 recipe:
# per-TU -O1 IR, llvm-link, ONE cq-lowering pass). e12 = the rail spelling,
# e13 = the compare spelling (the CONFIRMED miscompile, accepts on BOTH).
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=${CQ_ROOT:-/Users/sorenwilkening/Desktop/CQ_lang}
HERE=$(cd "$(dirname "$0")" && pwd)/multi
PRE=${CQ_PRE:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad/impl_b1/pre}
w=${1:-POST}
if [ "$w" = PRE ]; then O="$PRE/cq-opt"; P="$PRE/libCQPass.so"; else O="$ROOT/build/ir-pass/cq-opt"; P="$ROOT/build/ir-pass/libCQPass.so"; fi
T=$(mktemp -d)
for n in e12 e13 e16; do
  "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -emit-llvm -S "$HERE/${n}_caller.c" -o "$T/c.ll" 2>/dev/null
  "$LLVM/clang" -O1 -emit-llvm -S "$HERE/${n}_lib.c" -o "$T/l.ll" 2>/dev/null
  "$LLVM/llvm-link" -S "$T/c.ll" "$T/l.ll" -o "$T/s1.ll"
  "$O" -load-pass-plugin "$P" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>"$T/err"; rc=$?
  if [ $rc -ne 0 ]; then echo "$n $w rc=$rc $(grep -o 'cq [a-z ]*: [^;]*' "$T/err" | head -1)"
  else python3 "$ROOT/tools/free_pairing_check.py" "$T/s2.ll" > "$T/2b" 2>&1
       "$LLVM/clang" "$T/s2.ll" "$ROOT/build/runtime/libcq_templates.a" "$ROOT/build/runtime/libcq_runtime.a" -o "$T/a" 2>/dev/null && "$T/a" > "$T/tr"
       echo "$n $w rc=0 ACCEPT trace=$(wc -l < "$T/tr" | tr -d ' ') 2b=$(sed -n 's/.*: \([0-9]* verified.*\)/\1/p' "$T/2b" | head -1)"
       grep -n 'cqrt_ry_i32(h2' "$T/tr" | sed 's/^/    /'
  fi
done
rm -rf "$T"
