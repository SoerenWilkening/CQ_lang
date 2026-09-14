#!/usr/bin/env bash
# sweep_s2.sh (Track I, bd 21re) — lower every single-file e2e slice with the
# FROZEN ORACLE into $OUT, so `free_pairing_check.py` can be measured BEFORE and
# AFTER a change over the population stage 2b actually gates. Declines and
# multi-file slices produce no stage-2 module and are counted, not lowered.
# $OUT below was a scratch dir; point it anywhere writable and re-run from the
# repo root. Measured 2026-09-14: lowered=368 declined=21 stage1fail=20.
# Lower every single-file e2e slice .c in the Track I worktree with the FROZEN
# ORACLE, into $OUT. Accepts only; declines are recorded and skipped.
set -uo pipefail
LLVM=/usr/local/opt/llvm@19/bin
REPO=/Users/sorenwilkening/Desktop/CQ_inst
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass
OUT=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/36c1e541-2cdb-40ca-b58a-8d6de6acb155/scratchpad/s2
mkdir -p "$OUT"
ok=0; dec=0; s1f=0
for src in "$REPO"/tests/e2e/*.c; do
  b=$(basename "$src" .c)
  if ! "$LLVM/clang" -I"$REPO/include" -include CQ.h -O1 -emit-llvm -S "$src" -o "$OUT/$b.s1.ll" 2>/dev/null; then
    s1f=$((s1f+1)); rm -f "$OUT/$b.s1.ll"; continue
  fi
  if "$ORACLE/cq-opt" -load-pass-plugin "$ORACLE/libCQPass.so" -passes=cq-lowering \
       -S "$OUT/$b.s1.ll" -o "$OUT/$b.s2.ll" 2>/dev/null; then
    ok=$((ok+1))
  else
    dec=$((dec+1)); rm -f "$OUT/$b.s2.ll"
  fi
  rm -f "$OUT/$b.s1.ll"
done
echo "lowered=$ok declined=$dec stage1fail=$s1f"
