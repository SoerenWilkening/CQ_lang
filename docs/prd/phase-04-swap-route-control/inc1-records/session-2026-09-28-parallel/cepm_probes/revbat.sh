#!/bin/bash
# revbat.sh OUTDIR : both Rule-13 round-1 reviewers' probe batteries, run with THEIR harnesses, on
# the round-1b subject (before) and the round-2 subject (after). Stage-1 modules are the
# reviewers' own ($S/r1A_cepm/p, $S/r1B_cepm/p, built by their gen.sh from their src/).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
REC="$(cd "$(dirname "$0")/.." && pwd)"
OUT=$1; mkdir -p "$OUT"
A_LIST=$(ls "$REC/review_r1A_cepm/probes/src" | sed -n 's/^\(.*\)C\.c$/\1/p' | while read -r b; do [ -f "$REC/review_r1A_cepm/probes/src/${b}T.c" ] && echo "$b"; done)
B_LIST=$(ls "$REC/review_r1B_cepm/probes/src" | sed -n 's/^\(.*\)C\.c$/\1/p' | while read -r b; do [ -f "$REC/review_r1B_cepm/probes/src/${b}T.c" ] && echo "$b"; done)
for tag in subj2 subj3; do
  # shellcheck disable=SC2086
  bash "$REC/review_r1A_cepm/probes/twincmp.sh" "$S/cepm/cq-opt.$tag" $A_LIST > "$OUT/r1A_$tag.txt" 2>&1
  # shellcheck disable=SC2086
  bash "$REC/review_r1B_cepm/probes/twc.sh" "$S/cepm/cq-opt.$tag" "$tag" $B_LIST > "$OUT/r1B_$tag.txt" 2>&1
done
echo REVBAT_DONE > "$OUT/done"
