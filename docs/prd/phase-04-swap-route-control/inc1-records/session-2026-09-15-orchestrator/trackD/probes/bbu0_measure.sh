#!/bin/bash
# Track D — THE MEASUREMENT (bd `test_C_libtooling-bbu0`, owner ruling E6, option D).
#
# THE QUESTION: is `RotationLowering::warnLiveRecordRotations` ever SILENT on a
# module that `LoopLowering::declineDephasingUnmarkedLoopRails` DECLINES?
#
# It cannot be asked of a shipped binary: the fence is at CQLoweringPass.cpp:772,
# the warn stage at :864, and `LLVMContext::diagnose` EXITS on the first
# `DS_Error` (bd `br4a`) — so every "0 warnings" row on a declining module is
# 0 BY PREEMPTION, NOT BY SILENCE. The instrument this script drives defers the
# fence's decline past the warn stage under
# `CQ_BBU0_DEFER_DEPHASE_FENCE=1`; the decline is still emitted (later), so the
# gated mode can never turn a decline into an accept.
#
# ⚠ THE VACUITY GUARD IS THE MARKER, NOT THE COUNT (CLAUDE.md L10). A row is
# scored SILENT only when the instrument's own marker line
#   `cq bbu0 instrument: dephasing decline DEFERRED past the warn stage`
# is present, because that line is emitted BY the deferred emitter, which sits
# AFTER `warnLiveRecordRotations` in both entry points. Without the marker the
# pipeline did not reach the warn stage and the row is UNDECIDABLE — bucket
# PREEMPTED, never SILENT. A harness that scored "warn count 0" as SILENT would
# measure itself, which is the failure mode this project files against its own
# instruments.
#
# Usage: bbu0_measure.sh <population-file> <out.txt> [artifact-dir]
#   <population-file>: one path per line (relative to the worktree root), the
#                      modules on which the BASE binary emits the fence literal.
#   [artifact-dir]:    if given, every row that is NOT `WARNED` has its gated
#                      stderr and its lowered module saved there. A `SILENT` row
#                      is a finding and a finding that cannot be inspected is a
#                      claim; the shape is what the owner rules A/B/C on.
LLVM=/usr/local/opt/llvm@19/bin
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/CQ_D}
# ⚠ `OPT` is overridable ON PURPOSE, and the reason is Track T's measured trap of
# 2026-09-15: `cq-opt` can SEGFAULT while `libCQPass.so` from the SAME build
# works, with `make` reporting up to date — two targets, one source tree, and the
# only discriminator is running the same module through BOTH. Every row here
# therefore records WHICH binary produced it (`GATES.md`), and the key rows are
# re-run through the other one. Default is `cq-opt`; set e.g.
#   OPT="/usr/local/opt/llvm@19/bin/opt -load-pass-plugin $SUBJ/build/ir-pass/libCQPass.so"
# for the stock-opt spelling (the two are gated byte-equivalent).
OPT=${OPT:-"$SUBJ/build/ir-pass/cq-opt"}
POP=$1
OUT=$2
ART=$3
[ -n "$ART" ] && mkdir -p "$ART"
FENCE='rolled body leaks a rail entangled with a rotated register'
WARN='non-diagonal gate over a live derived record'
MARK='cq bbu0 instrument: dephasing decline DEFERRED past the warn stage'
: > "$OUT"
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  f="$SUBJ/$rel"
  T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR"; rm -rf "$T"; continue; }
  else cp "$f" "$T/s1.ll"; fi

  # (0) CONTROL — env UNSET. Must still be the fence's decline, unchanged.
  $OPT -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>"$T/off.err"; e0=$?
  if [ $e0 -eq 0 ] || ! grep -qF "$FENCE" "$T/off.err"; then
    echo "$rel|CONTROL-BROKEN|exit=$e0"; rm -rf "$T"; continue
  fi

  # (1) GATED — env SET. The decline is deferred past the warn stage.
  CQ_BBU0_DEFER_DEPHASE_FENCE=1 $OPT -passes=cq-lowering -S "$T/s1.ll" \
      -o "$T/on.ll" 2>"$T/on.err"; e1=$?
  w=$(grep -cF "$WARN" "$T/on.err")
  m=$(grep -cF "$MARK" "$T/on.err")
  fz=$(grep -cF "$FENCE" "$T/on.err")

  if [ $e1 -gt 128 ]; then
    b=CRASH
  elif [ "$m" -eq 0 ]; then
    b=PREEMPTED
  elif [ "$fz" -eq 0 ]; then
    b=INSTRUMENT-BROKEN          # marker without the decline: must never happen
  elif [ "$w" -gt 0 ]; then
    b=WARNED
  else
    b=SILENT
  fi
  # the first diagnostic line of the gated run, so a PREEMPTED row names its owner
  first=$(grep -m1 -E '^(warning|error|.*: (error|warning))' "$T/on.err" | cut -c1-140)
  [ -z "$first" ] && first=$(head -1 "$T/on.err" | cut -c1-140)
  if [ -n "$ART" ] && [ "$b" != WARNED ]; then
    tag=$(echo "$rel" | tr '/.' '__')
    cp -f "$T/on.err" "$ART/$tag.$b.err" 2>/dev/null
    cp -f "$T/on.ll"  "$ART/$tag.$b.ll"  2>/dev/null
    cp -f "$T/s1.ll"  "$ART/$tag.$b.s1.ll" 2>/dev/null
  fi
  echo "$rel|$b|exit=$e1|warn=$w|marker=$m|fence=$fz|$first"
  rm -rf "$T"
done < "$POP" >> "$OUT"
echo DONE >> "$OUT"
