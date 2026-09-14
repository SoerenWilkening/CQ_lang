#!/bin/bash
# Track S' (session 2026-09-15) per-probe harness.  Derived from Track beta's
# rb.sh (r13-r1-beta) and RE-ATTACKED here before use (CLAUDE.md L10):
#   * stage-1 emptiness / no-quantum is DETECTED and reported VACUOUS — a 0-byte
#     or quantum-free module ACCEPTS through the passthrough early-out
#     (bd memory `empty-module-accepts-vacuity-trap`).
#   * every derived artifact is DELETED before the run, so a stale trace cannot
#     make a run that never linked look like an accept.
#   * a link failure and an empty `opt` output are reported as their own tags,
#     never as an accept.
# Usage: ps.sh <probe.c> [more.c ...]
set -u
LLVM=/usr/local/opt/llvm@19/bin
ORA=/Users/sorenwilkening/Desktop/CQ_lang/build
SUB=/Users/sorenwilkening/Desktop/CQ_S/build
REPO=/Users/sorenwilkening/Desktop/CQ_S
row() {
  local P="$1" B D NQ O S
  B=$(basename "$P" .c); D=$(dirname "$P")
  rm -f "$D/$B".s1.ll "$D/$B".{ora,sub}.ll "$D/$B".{ora,sub}.err \
        "$D/$B".{ora,sub}.trace "$D/$B".{ora,sub}.bin "$D/$B".clang.err
  "$LLVM/clang" -I"$REPO/include" -include CQ.h -O1 -g -emit-llvm -S "$P" \
      -o "$D/$B.s1.ll" 2> "$D/$B.clang.err"
  if [ ! -s "$D/$B.s1.ll" ]; then echo "$B | CLANGERR"; return 1; fi
  NQ=$(grep -c 'call .*@cq_\(theta\|phi\|measure\)_' "$D/$B.s1.ll")
  if [ "$NQ" -eq 0 ]; then
    echo "$B | VACUOUS-NO-QUANTUM (0 cq_* calls in stage 1; an ACCEPT here is the passthrough early-out)"
    return 2
  fi
  O=$(run "$D" "$B" ora "$ORA"); S=$(run "$D" "$B" sub "$SUB")
  echo "$B | ORACLE $O | SUBJECT $S"
}
run() {
  local D=$1 B=$2 T=$3 BD=$4 E
  "$BD/ir-pass/cq-opt" -load-pass-plugin "$BD/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$D/$B.s1.ll" -o "$D/$B.$T.ll" 2> "$D/$B.$T.err"; E=$?
  if [ $E -ne 0 ]; then
     printf 'D%s:%s' "$E" "$(grep -o 'cq [a-z ]*lowering: [^;]*\|cq taint escape: [^;]*\|cq opcode lowering: [^;]*' "$D/$B.$T.err" | head -1)"
     return
  fi
  if [ ! -s "$D/$B.$T.ll" ]; then printf 'BROKEN-EMPTY-OUTPUT'; return; fi
  "$LLVM/clang" "$D/$B.$T.ll" "$BD/runtime/libcq_templates.a" "$BD/runtime/libcq_runtime.a" \
      -o "$D/$B.$T.bin" 2>/dev/null
  if [ ! -x "$D/$B.$T.bin" ]; then printf 'A:LINKFAIL'; return; fi
  "$D/$B.$T.bin" > "$D/$B.$T.trace" 2>/dev/null
  printf 'A:%s lines' "$(wc -l < "$D/$B.$T.trace" | tr -d ' ')"
}
for p in "$@"; do row "$p"; done
