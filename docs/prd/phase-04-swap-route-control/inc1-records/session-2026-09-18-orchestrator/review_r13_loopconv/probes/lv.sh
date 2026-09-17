#!/bin/bash
# lv.sh — ONE probe .c through the ORACLE pipeline. Self-guarded (bd memory
# empty-module-accepts-vacuity-trap): a 0-byte or quantum-free .c reports
# VACUOUS-NO-QUANTUM, never ACCEPT.
set -u
REPO=/Users/sorenwilkening/Desktop/Projects/CQ_lang
LLVM=/usr/local/opt/llvm@19/bin
BUILD=$REPO/build
W=$(cd "$(dirname "$0")" && pwd)/work
mkdir -p "$W"
SRC="$1"; BASE=$(basename "$SRC" .c)
if [ ! -s "$SRC" ]; then echo "$BASE | VACUOUS-EMPTY-SOURCE"; exit 0; fi
"$LLVM/clang" -I"$REPO/include" -include CQ.h -O1 -g -emit-llvm -S "$SRC" -o "$W/$BASE.s1.ll" 2> "$W/$BASE.cc.err"
if [ $? -ne 0 ]; then echo "$BASE | STAGE1-FAIL"; sed -n 1,5p "$W/$BASE.cc.err"; exit 0; fi
NQ=$(grep -c 'call .*@cq_\(theta\|phi\|measure\)' "$W/$BASE.s1.ll")
if [ "$NQ" -eq 0 ]; then echo "$BASE | VACUOUS-NO-QUANTUM"; exit 0; fi
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering \
   -S "$W/$BASE.s1.ll" -o "$W/$BASE.s2.ll" 2> "$W/$BASE.opt.err"
RC=$?
if [ $RC -ne 0 ]; then
  echo "$BASE | DECLINE(exit=$RC) | $(tr -d '\n' < "$W/$BASE.opt.err" | sed 's/.*error: //;s/ *$//' | cut -c1-140)"
  exit 0
fi
if [ -s "$W/$BASE.opt.err" ]; then echo "$BASE | (stderr non-empty on accept): $(head -c 200 "$W/$BASE.opt.err")"; fi
P2B=$(cd "$REPO" && python3 tools/free_pairing_check.py "$W/$BASE.s2.ll" 2>&1 | tr '\n' ' ')
case "$P2B" in *"cannot read"*|"") echo "$BASE | INSTRUMENT-BROKEN-2B: $P2B"; exit 2;; esac
"$LLVM/clang" "$W/$BASE.s2.ll" "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o "$W/$BASE.bin" 2> "$W/$BASE.link.err"
if [ $? -ne 0 ]; then echo "$BASE | A:LINKFAIL | $(head -c 200 "$W/$BASE.link.err")"; exit 0; fi
"$W/$BASE.bin" > "$W/$BASE.trace" 2>&1
N=$(wc -l < "$W/$BASE.trace" | tr -d ' ')
if [ "$N" -eq 0 ]; then echo "$BASE | BROKEN-EMPTY-OUTPUT"; exit 0; fi
echo "$BASE | ACCEPT | trace=$N | 2b: $P2B"
