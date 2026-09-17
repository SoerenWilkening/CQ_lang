#!/bin/bash
# corpus_x.sh — Track X's ORACLE-vs-SUBJECT sweep (session 2026-09-18).
#
# Same recipe as session-2026-09-11-orchestrator/review_integration_probes/corpus.sh
# with THREE corrections, each of which that file needs anyway:
#   * the repo MOVED (2026-09-17) — every older PROTOCOL/corpus.sh names
#     ~/Desktop/CQ_lang; ORC/SUBJ are arguments here, never hard-coded;
#   * the corpus is PROTOCOL.md's, not that file's frozen 11-directory list:
#     ir-pass/test/*.ll plus every session dir's track*/probes and
#     review_*_probes;
#   * PROTOCOL.md §S3 records that the shared tag regex renders the whole
#     `cq_measure_<sfx>` family as an EMPTY `D:`, so a decline->decline change
#     inside it is INVISIBLE. This version records the FULL first error line
#     (after stripping the file path), so a D->D move inside any family shows.
#
# Row: <relpath>|<oracle verdict>|<subject verdict>
#   A:<md5 of lowered IR, first 8>   accept   (md5s are NOT comparable across
#                                              sweeps — only within a row)
#   D:<full first diagnostic>        decline
set -u
LLVM=/usr/local/opt/llvm@19/bin
ORC=${ORC:?usage: ORC=<oracle repo root> SUBJ=<subject repo root> corpus_x.sh <out>}
SUBJ=${SUBJ:?}
OUT=${1:?}
: > "$OUT"

list_corpus() {
  ls "$SUBJ"/ir-pass/test/*.ll 2>/dev/null
  find "$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records" \
       -type d \( -name probes -o -name 'review_*_probes' \) 2>/dev/null |
    while read -r d; do
      find "$d" \( -name '*.c' -o -name '*.ll' \) 2>/dev/null
    done
}

v() { # $1 = repo root, $2 = tag, $3 = tmpdir
  "$1/build/ir-pass/cq-opt" -load-pass-plugin "$1/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$3/s1.ll" -o "$3/$2.ll" 2>"$3/$2.err"
  if [ $? -eq 0 ]; then
    echo "A:$(md5 -q "$3/$2.ll" | cut -c1-8)"
  else
    echo "D:$(grep -m1 '^error:' "$3/$2.err" | sed -E 's#^error: [^ ]*: ##' | cut -c1-140)"
  fi
}

n=0
list_corpus | sort -u | while read -r f; do
  T=$(mktemp -d)
  rel=${f#"$SUBJ"/}
  case "$f" in
    *.c)
      base=$(basename "$f")
      case "$base" in
        *_lib.c|lib*.c) rm -rf "$T"; continue ;;
      esac
      "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
        || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; continue; } ;;
    *) cp -f "$f" "$T/s1.ll" ;;
  esac
  # (V0) a 0-byte / bodyless module ACCEPTS through the passthrough early-out.
  if ! grep -q '^define' "$T/s1.ll" 2>/dev/null; then
    echo "$rel|NOBODY|NOBODY" >> "$OUT"; rm -rf "$T"; continue
  fi
  echo "$rel|$(v "$ORC" o "$T")|$(v "$SUBJ" s "$T")" >> "$OUT"
  rm -rf "$T"
  n=$((n+1))
done
echo DONE >> "$OUT"
