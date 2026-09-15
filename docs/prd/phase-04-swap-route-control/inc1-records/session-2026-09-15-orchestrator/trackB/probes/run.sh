#!/bin/sh
# Track B (session 2026-09-15) per-probe driver — PROTOCOL.md pipeline, frozen ORACLE.
# usage: ./probes/run.sh <probe>.c     (run from the repo root)
set -u
LLVM=/usr/local/opt/llvm@19/bin
BUILD=${BUILD:-build}
W=${W:-/tmp/cqtrackB}; mkdir -p "$W"
P="$1"; B=$(basename "$P" .c)
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$W/$B.s1.ll" || exit 9
out=$("$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$W/$B.s1.ll" -o "$W/$B.s2.ll" 2>&1); rc=$?
if [ $rc -ne 0 ]; then
  echo "$B: DECLINE  $(printf '%s' "$out" | sed -n '1s/.*: cq /cq /p')"
  exit 0
fi
pair=$(python3 tools/free_pairing_check.py "$W/$B.s2.ll" 2>&1 | tail -1)
"$LLVM/clang" "$W/$B.s2.ll" "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" \
      -o "$W/$B.exe" 2>/dev/null && "$W/$B.exe" > "$W/$B.trace" 2>&1
echo "$B: ACCEPT  trace=$(wc -l < "$W/$B.trace" | tr -d ' ') lines | 2b: $pair"
