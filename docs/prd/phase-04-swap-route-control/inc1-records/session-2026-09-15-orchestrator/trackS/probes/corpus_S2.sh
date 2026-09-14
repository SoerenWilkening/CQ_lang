#!/bin/bash
# Track S' corpus sweep — ORACLE vs SUBJECT over the whole probe+fixture corpus.
# Derived from $SES/../session-2026-09-11-orchestrator/review_integration_probes/corpus.sh
# with THREE changes, each closing an instrument lesson PROTOCOL S3 records:
#   * a row carries the EXIT CODE and a SHA-256 OF THE FULL STDERR, not only a
#     regex-extracted tag — the shared tag regex renders the whole
#     `cq_measure_<sfx>` family as an empty `D:`, so a decline->decline string
#     change inside it is INVISIBLE.
#   * lowered-IR md5s are compared WITHIN a row only (the temp `ModuleID`
#     differs across sweeps), which is why both binaries read the SAME stage-1.
#   * a stage-1 with zero `cq_{theta,phi,measure}` calls is tagged VACUOUS — a
#     0-byte or quantum-free module ACCEPTS through the passthrough early-out.
# Usage: corpus_S2.sh <out.txt>
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_S
OUT=$1
: > "$OUT"
row() {
  f="$1"; rel="${f#$SUBJ/}"; T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    b=$(basename "$f")
    case "$b" in *_lib.c|lib*.c) rm -rf "$T"; return;; esac
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR"; rm -rf "$T"; return; }
  else cp "$f" "$T/s1.ll"; fi
  if [ ! -s "$T/s1.ll" ] || ! grep -q '@cq_\(theta\|phi\|measure\)_' "$T/s1.ll"; then
    echo "$rel|VACUOUS|VACUOUS"; rm -rf "$T"; return
  fi
  v() { local root=$1 tag=$2 e
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"; e=$?
    if [ $e -eq 0 ]; then printf 'A:%s:%s' "$(md5 -q "$T/$tag.ll" | cut -c1-8)" \
        "$(shasum -a 256 "$T/$tag.err" | cut -c1-8)"
    else printf 'D%s:%s' "$e" "$(shasum -a 256 "$T/$tag.err" | cut -c1-8)"; fi
  }
  echo "$rel|$(v $ORC o)|$(v $SUBJ s)"
  rm -rf "$T"
}
export -f row; export LLVM ORC SUBJ
{ ls "$SUBJ"/ir-pass/test/*.ll
  find "$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records" \
       \( -path '*/probes/*' -o -path '*_probes/*' \) \
       \( -name '*.c' -o -name '*.ll' \) ! -name '*.s1.ll' ! -name '*.ora.ll' \
       ! -name '*.sub.ll' ! -name '*.sora.ll' ! -name '*.ssub.ll' | sort
} | xargs -P 6 -I{} bash -c 'row "$@"' _ {} >> "$OUT"
echo DONE >> "$OUT"
