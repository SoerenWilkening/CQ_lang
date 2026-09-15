#!/bin/bash
# Track D — enumerate THE POPULATION: every module on which the BASE binary
# emits `LoopLowering::declineDephasingUnmarkedLoopRails`' literal.
#
# The population is derived, never hand-listed: `MEASUREMENT.md`'s denominator
# is whatever this prints, so the number and its population cannot drift apart
# (the failure mode CLAUDE.md files against `probe.cq_provided_cells()`'s
# would-be hand list).
#
# ⚠ VACUITY GUARD (bd memory `empty-module-accepts-vacuity-trap`): a 0-byte or
# quantum-free module ACCEPTS through the passthrough early-out, so it can never
# be in this population — but it would silently pad a denominator, so it is
# tagged and excluded rather than skipped in silence.
#
# Usage: fence_pop.sh <BASE_CQOPT> <out.txt>   (one relative path per FENCE row)
LLVM=/usr/local/opt/llvm@19/bin
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/CQ_D}
BASE_OPT=$1
OUT=$2
FENCE='rolled body leaks a rail entangled with a rotated register'
: > "$OUT.raw"
scan() {
  f="$1"; rel="${f#$SUBJ/}"; T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    b=$(basename "$f")
    case "$b" in *_lib.c|lib*.c) rm -rf "$T"; return;; esac
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR"; rm -rf "$T"; return; }
  else cp "$f" "$T/s1.ll"; fi
  if [ ! -s "$T/s1.ll" ] || ! grep -q '@cq_\(theta\|phi\|measure\)_' "$T/s1.ll"; then
    echo "$rel|VACUOUS"; rm -rf "$T"; return
  fi
  "$BASE_OPT" -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>"$T/e"; e=$?
  if grep -qF "$FENCE" "$T/e"; then echo "$rel|FENCE|exit=$e"
  elif [ $e -eq 0 ]; then echo "$rel|ACCEPT"
  else echo "$rel|OTHERDECLINE"; fi
  rm -rf "$T"
}
export -f scan; export LLVM SUBJ BASE_OPT FENCE
# SCOPE: default = the brief's minimum (`ir-pass/test/*.ll` + THIS session's probe
# corpora). `POP_SCOPE=full` widens the second half to EVERY session's probe dirs
# — the same corpus PROTOCOL names for the sweep. The minimum is run first
# because it is the population the owner's ruling is about; `full` is reported
# beside it, never merged into it (two corpora, two denominators).
ROOTS="$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator"
[ "$POP_SCOPE" = full ] && ROOTS="$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records"
{ ls "$SUBJ"/ir-pass/test/*.ll
  find "$ROOTS" \
       \( -path '*/probes/*' -o -path '*_probes/*' \) \
       \( -name '*.c' -o -name '*.ll' \) ! -name '*.ora.ll' ! -name '*.sub.ll' \
       ! -name '*.sora.ll' ! -name '*.ssub.ll' | sort
} | xargs -P 4 -I{} bash -c 'scan "$@"' _ {} >> "$OUT.raw"
grep '|FENCE|' "$OUT.raw" | cut -d'|' -f1 | sort > "$OUT"
echo "population: $(wc -l < "$OUT") FENCE rows of $(grep -c . "$OUT.raw") scanned" >&2
