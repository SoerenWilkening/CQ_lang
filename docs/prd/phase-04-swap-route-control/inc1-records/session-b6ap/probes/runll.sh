#!/usr/bin/env bash
# usage: runll.sh <name>   (expects <name>.s1.ll in the same dir — HAND-EDITED IR)
ROOT=/Users/sorenwilkening/Desktop/CQ_lang
SP="$(cd "$(dirname "$0")" && pwd)"
LLVM=/usr/local/opt/llvm@19/bin
N=$1
cd "$SP"
"$ROOT/build/ir-pass/cq-opt" -load-pass-plugin "$ROOT/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$N.s1.ll" -o "$N.s2.ll" > "$N.opt.out" 2> "$N.opt.err"
RC=$?
echo "=== $N  exit=$RC ==="
echo "--- stderr ---"; cat "$N.opt.err"
if [ $RC -eq 0 ]; then
  "$LLVM/clang" "$N.s2.ll" "$ROOT/build/runtime/libcq_templates.a" "$ROOT/build/runtime/libcq_runtime.a" -o "$N.exe" 2>/dev/null && { ./"$N.exe" > "$N.trace" 2>&1; echo "--- trace ($(wc -l < "$N.trace") lines) ---"; cat "$N.trace"; } || echo "LINK-OR-RUN-FAIL"
  echo "--- 2b ---"; (cd "$ROOT" && python3 tools/free_pairing_check.py "$SP/$N.s2.ll" 2>&1 | tail -3)
fi
