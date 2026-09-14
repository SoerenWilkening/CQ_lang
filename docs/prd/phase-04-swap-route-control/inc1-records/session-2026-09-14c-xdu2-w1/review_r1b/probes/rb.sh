#!/bin/bash
# Track beta (Rule-13 r1) per-probe harness. NOT Track S's.
# Usage: rb.sh <probe.c>
# Emits one row: name | ORACLE(exit,tag,trace-lines) | SUBJECT(exit,tag,trace-lines)
# INSTRUMENT DISCIPLINE (CLAUDE.md L10):
#   * stage-1 emptiness / no-quantum is DETECTED and reported as VACUOUS, because a
#     0-byte or quantum-free module ACCEPTS through the passthrough early-out.
#   * every derived artifact is DELETED before the run, so a stale trace cannot
#     make a run that never linked look like an accept.
#   * trace line counts come from a file whose mtime is checked against the run.
set -u
LLVM=/usr/local/opt/llvm@19/bin
ORA=/Users/sorenwilkening/Desktop/CQ_lang/build
SUB=/Users/sorenwilkening/Desktop/CQ_merge/build
REPO=/Users/sorenwilkening/Desktop/CQ_rev_b
P="$1"; B=$(basename "$P" .c); D=$(dirname "$P")
rm -f "$D/$B".s1.ll "$D/$B".{ora,sub}.ll "$D/$B".{ora,sub}.err "$D/$B".{ora,sub}.trace "$D/$B".{ora,sub}.bin
"$LLVM/clang" -I"$REPO/include" -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$D/$B.s1.ll" 2> "$D/$B.clang.err"
if [ ! -s "$D/$B.s1.ll" ]; then echo "$B | CLANGERR"; cat "$D/$B.clang.err" >&2; exit 1; fi
# VACUITY GUARD: a module with no cq_* intrinsic call ACCEPTS through the passthrough early-out.
NQ=$(grep -c 'call .*@cq_\(theta\|phi\|measure\)_' "$D/$B.s1.ll")
if [ "$NQ" -eq 0 ]; then echo "$B | VACUOUS-NO-QUANTUM (stage-1 has 0 cq_* calls; an ACCEPT here is the passthrough early-out, not a lowering)"; exit 2; fi
run() { # $1=tag $2=build
  local T=$1 BD=$2
  "$BD/ir-pass/cq-opt" -load-pass-plugin "$BD/ir-pass/libCQPass.so" -passes=cq-lowering \
      -S "$D/$B.s1.ll" -o "$D/$B.$T.ll" 2> "$D/$B.$T.err"; local E=$?
  if [ $E -ne 0 ]; then
     printf '%s' "D$E:$(grep -o 'cq [a-z ]*lowering: [^;]*\|cq taint escape: [^;]*\|cq opcode lowering: [^;]*' "$D/$B.$T.err" | head -1)"
     return
  fi
  if [ ! -s "$D/$B.$T.ll" ]; then printf 'BROKEN-EMPTY-OUTPUT'; return; fi
  "$LLVM/clang" "$D/$B.$T.ll" "$BD/runtime/libcq_templates.a" "$BD/runtime/libcq_runtime.a" -o "$D/$B.$T.bin" 2>/dev/null
  if [ ! -x "$D/$B.$T.bin" ]; then printf 'A:LINKFAIL'; return; fi
  "$D/$B.$T.bin" > "$D/$B.$T.trace" 2>/dev/null
  printf 'A:%s lines' "$(wc -l < "$D/$B.$T.trace" | tr -d ' ')"
}
O=$(run ora "$ORA"); S=$(run sub "$SUB")
echo "$B | ORACLE $O | SUBJECT $S"
