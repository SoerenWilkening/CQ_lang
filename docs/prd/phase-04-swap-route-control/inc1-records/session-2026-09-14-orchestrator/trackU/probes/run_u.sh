#!/bin/bash
# run_u.sh — Track U per-probe pipeline (PROTOCOL.md verbatim).
#   usage: run_u.sh <BUILD_DIR> <INCLUDE_ROOT> <probe.c> [probe.c ...]
# Prints one row per probe: exit code, diagnostic string, trace line count.
LLVM=/usr/local/opt/llvm@19/bin
BUILD="$1"; shift
ROOT="$1"; shift
echo "# binary: $(shasum -a 256 "$BUILD/ir-pass/cq-opt" | cut -c1-16)  plugin: $(shasum -a 256 "$BUILD/ir-pass/libCQPass.so" | cut -c1-16)"
for p in "$@"; do
  n=$(basename "$p" .c)
  d=$(mktemp -d)
  "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$p" -o "$d/s1.ll" 2> "$d/c1.err" || { echo "$n | STAGE1-FAIL"; continue; }
  "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S "$d/s1.ll" -o "$d/s2.ll" > "$d/out.txt" 2> "$d/err.txt"
  rc=$?
  if [ $rc -ne 0 ]; then
    msg=$(grep -o 'cq [^;]*' "$d/err.txt" | head -1)
    [ -z "$msg" ] && msg=$(head -2 "$d/err.txt" | tr '\n' ' ')
    echo "$n | exit=$rc | DECLINE | $msg"
  else
    fp=$(cd "$ROOT" && python3 tools/free_pairing_check.py "$d/s2.ll" 2>&1 | tail -1)
    "$LLVM/clang" "$d/s2.ll" "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o "$d/a" 2> "$d/link.err"
    if [ -x "$d/a" ]; then "$d/a" > "$d/trace.txt" 2>&1; lines=$(wc -l < "$d/trace.txt" | tr -d ' '); else lines="LINKFAIL"; fi
    seeds=$(grep -o 'cqrt_alloc_[a-z0-9]*(\([^)]*\))' "$d/s2.ll" | head -6 | tr '\n' ' ')
    echo "$n | exit=0 | ACCEPT | trace=$lines | 2b: $fp | allocs: $seeds"
    cp -f "$d/trace.txt" "$(dirname "$0")/$n.trace" 2>/dev/null
    cp -f "$d/s2.ll" "$(dirname "$0")/$n.s2.ll" 2>/dev/null
  fi
  rm -rf "$d"
done
