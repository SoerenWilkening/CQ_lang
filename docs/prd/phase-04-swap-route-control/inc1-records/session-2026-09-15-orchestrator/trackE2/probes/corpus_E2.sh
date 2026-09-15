#!/bin/bash
# Track E2 corpus sweep — ORACLE vs SUBJECT over the whole probe+fixture corpus.
# Derived from trackS/probes/corpus_S2.sh (itself derived from
# session-2026-09-11-orchestrator/review_integration_probes/corpus.sh) with the
# three PROTOCOL S3 corrections it already carries — exit code + FULL-stderr
# sha-256 instead of the tag regex (which renders the whole `cq_measure_<sfx>`
# family as an empty `D:` and would make E2's OWN string move invisible),
# within-row md5 comparison, and a VACUOUS tag for a quantum-free stage-1 —
# PLUS one E2 addition:
#   * each row carries the FIRST STDERR LINE of BOTH binaries, sanitised, so the
#     population of a named decline string can be CENSUSED from the sweep rather
#     than grepped for (a grep over source is a lower bound, never a census).
# Usage: corpus_E2.sh <out.txt>
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_E2
OUT=$1
: > "$OUT"
row() {
  f="$1"; rel="${f#$SUBJ/}"; T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    b=$(basename "$f")
    case "$b" in *_lib.c|lib*.c) rm -rf "$T"; return;; esac
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR||"; rm -rf "$T"; return; }
  else cp "$f" "$T/s1.ll"; fi
  if [ ! -s "$T/s1.ll" ] || ! grep -q '@cq_\(theta\|phi\|measure\)_' "$T/s1.ll"; then
    echo "$rel|VACUOUS|VACUOUS||"; rm -rf "$T"; return
  fi
  # ⚠ BOTH BINARIES READ THE **SAME** INPUT FILE. An earlier spelling of this
  # script copied the stage-1 to `o.in.ll` and `s.in.ll` so each binary had its
  # own input; the lowered `; ModuleID` line is derived from the INPUT PATH, so
  # every accepting row then reported two different md5s and the whole md5 axis
  # read as "everything moved". Measured on the aborted first run: 267 of 267
  # A:A rows "differing". A harness that reports a move on every row measures
  # itself, not the compiler (PROTOCOL S3 / CLAUDE.md L10).
  v() { local root=$1 tag=$2 e
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"; e=$?
    if [ $e -eq 0 ]; then printf 'A:%s:%s' "$(md5 -q "$T/$tag.ll" | cut -c1-8)" \
        "$(shasum -a 256 "$T/$tag.err" | cut -c1-8)"
    else printf 'D%s:%s' "$e" "$(shasum -a 256 "$T/$tag.err" | cut -c1-8)"; fi
  }
  # ⚠ ERRATUM, measured on the committed sweep: at `cut -c1-160` a row whose
  # PATH is long has its diagnostic TRUNCATED, and `cq_measure_<sfx> operand is
  # an undef/poison literal...` truncates to a prefix that `cq_measure_<sfx>
  # operand not recognized...` also has. Three of the committed sweep's movers
  # were re-measured individually to attribute them; the cut is widened here so
  # the next user does not have to. A truncation that makes two DIFFERENT
  # diagnostics look alike is the same defect class as the shared tag regex this
  # script was written to replace.
  msg() { head -1 "$1" 2>/dev/null | tr -d '\n' | tr '|' '/' | cut -c1-400; }
  # (no per-binary input copies — see the note on v() above)
  O=$(v $ORC o); S=$(v $SUBJ s)
  echo "$rel|$O|$S|$(msg $T/o.err)|$(msg $T/s.err)"
  rm -rf "$T"
}
export -f row; export LLVM ORC SUBJ
{ ls "$SUBJ"/ir-pass/test/*.ll
  find "$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records" \
       \( -path '*/probes/*' -o -path '*_probes/*' \) \
       \( -name '*.c' -o -name '*.ll' \) ! -name '*.s1.ll' ! -name '*.ora.ll' \
       ! -name '*.sub.ll' ! -name '*.sora.ll' ! -name '*.ssub.ll' \
       ! -name '*.s2.ll' ! -name '*.zero.ll' | sort
} | xargs -P 6 -I{} bash -c 'row "$@"' _ {} >> "$OUT"
echo DONE >> "$OUT"
