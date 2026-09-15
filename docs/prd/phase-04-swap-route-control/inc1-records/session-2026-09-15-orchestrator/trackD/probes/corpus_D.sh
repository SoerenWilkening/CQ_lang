#!/bin/bash
# Track D corpus sweep — BASE vs SUBJECT, env UNSET, over the whole
# fixture+probe corpus. THIS IS THE "NO VERDICT MOVED" GATE for the bbu0
# instrument: with `CQ_BBU0_DEFER_DEPHASE_FENCE` unset the subject must be
# indistinguishable from its base on every row.
#
# Derived from $SES/trackS/probes/corpus_S2.sh (Track S'), which is itself
# derived from session-2026-09-11's review_integration_probes/corpus.sh, with
# S' three instrument corrections KEPT VERBATIM:
#   * a row carries the EXIT CODE and a SHA-256 OF THE FULL STDERR, not a
#     regex-extracted tag (the shared tag regex hides a decline->decline string
#     move inside the `cq_measure_<sfx>` family — PROTOCOL S3);
#   * lowered-IR md5s are compared WITHIN a row only (the temp `ModuleID`
#     differs across sweeps), which is why both binaries read the SAME stage-1;
#   * a stage-1 with zero `cq_{theta,phi,measure}` calls is tagged VACUOUS — a
#     0-byte or quantum-free module ACCEPTS through the passthrough early-out
#     (bd memory `empty-module-accepts-vacuity-trap`).
# ONE addition of my own: a trailing FENCE field recording whether the BASE
# binary emitted `declineDephasingUnmarkedLoopRails`' literal on that row. That
# field IS the population of MEASUREMENT.md — it is derived by the same sweep
# that proves nothing moved, so the two numbers cannot drift apart.
#
# Usage: corpus_D.sh <out.txt> [BASE_CQOPT] [SUBJ_ROOT]
LLVM=/usr/local/opt/llvm@19/bin
BASE_OPT=${2:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/1c53d18f-fd04-48d9-8e6f-94acf28a1db2/scratchpad/base/cq-opt}
SUBJ=${3:-/Users/sorenwilkening/Desktop/CQ_D}
OUT=$1
FENCE='rolled body leaks a rail entangled with a rotated register'
: > "$OUT"
row() {
  f="$1"; rel="${f#$SUBJ/}"; T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    b=$(basename "$f")
    case "$b" in *_lib.c|lib*.c) rm -rf "$T"; return;; esac
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR|-"; rm -rf "$T"; return; }
  else cp "$f" "$T/s1.ll"; fi
  if [ ! -s "$T/s1.ll" ] || ! grep -q '@cq_\(theta\|phi\|measure\)_' "$T/s1.ll"; then
    echo "$rel|VACUOUS|VACUOUS|-"; rm -rf "$T"; return
  fi
  v() { local opt=$1 tag=$2 e
    "$opt" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"; e=$?
    if [ $e -eq 0 ]; then printf 'A:%s:%s' "$(md5 -q "$T/$tag.ll" | cut -c1-8)" \
        "$(shasum -a 256 "$T/$tag.err" | cut -c1-8)"
    else printf 'D%s:%s' "$e" "$(shasum -a 256 "$T/$tag.err" | cut -c1-8)"; fi
  }
  B=$(v "$BASE_OPT" b)
  S=$(v "$SUBJ/build/ir-pass/cq-opt" s)
  if grep -qF "$FENCE" "$T/b.err"; then FL=FENCE; else FL=-; fi
  echo "$rel|$B|$S|$FL"
  rm -rf "$T"
}
export -f row; export LLVM BASE_OPT SUBJ FENCE
{ ls "$SUBJ"/ir-pass/test/*.ll
  find "$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records" \
       \( -path '*/probes/*' -o -path '*_probes/*' \) \
       \( -name '*.c' -o -name '*.ll' \) ! -name '*.s1.ll' ! -name '*.ora.ll' \
       ! -name '*.sub.ll' ! -name '*.sora.ll' ! -name '*.ssub.ll' | sort
} | xargs -P 4 -I{} bash -c 'row "$@"' _ {} >> "$OUT"
echo DONE >> "$OUT"
