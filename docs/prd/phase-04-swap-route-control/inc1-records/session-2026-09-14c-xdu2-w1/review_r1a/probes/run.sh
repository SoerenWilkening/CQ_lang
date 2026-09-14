#!/bin/bash
# REVIEW R1A per-probe pipeline (PROTOCOL.md). SUBJECT vs ORACLE on the SAME stage-1 file.
# Usage: run.sh <probe.c|probe.ll> [extra clang flags]
# Prints, for each binary: exit code, first diagnostic line, lowered-IR line count.
set -uo pipefail
LLVM=/usr/local/opt/llvm@19/bin
ROOT=/Users/sorenwilkening/Desktop/CQ_rev_a
SUBJ=/Users/sorenwilkening/Desktop/CQ_merge/build
ORAC=/Users/sorenwilkening/Desktop/CQ_lang/build
P="$1"; shift || true
B=$(basename "$P"); B="${B%.*}"
T=$(mktemp -d)
if [[ "$P" == *.ll ]]; then cp "$P" "$T/s1.ll"; else
  "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$@" "$P" -o "$T/s1.ll" || { echo "$B: CLANG-FAIL"; exit 9; }
fi
# HARNESS SELF-CHECK (L10): a stage-1 module with no cq_* intrinsic call is a
# VACUOUS probe (the pass passthrough early-outs and every binary says exit 0).
NCQ=$(grep -c 'call .*@cq_\(theta\|phi\|measure\)_' "$T/s1.ll" || true)
NFN=$(grep -c '^define ' "$T/s1.ll" || true)
for W in SUBJ ORAC; do
  D=${!W}
  "$D/ir-pass/cq-opt" -load-pass-plugin "$D/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$W.ll" 2> "$T/$W.err"
  E=$?
  MSG=$(grep -o "cq [a-z0-9 ]*[a-z]*:[^']*" "$T/$W.err" | head -1)
  [ -z "$MSG" ] && MSG=$(head -2 "$T/$W.err" | tr '\n' ' ' | cut -c1-140)
  LN=$( [ $E -eq 0 ] && grep -c '' "$T/$W.ll" || echo "-")
  printf '%-6s %-4s exit=%s lines=%-5s %s\n' "$B" "$W" "$E" "$LN" "${MSG:-<none>}"
done
echo "         [harness] cq_intrinsic_calls=$NCQ defines=$NFN  tmp=$T"
