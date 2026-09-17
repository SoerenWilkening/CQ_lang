#!/bin/bash
# corpus_par.sh — the PARALLEL driver for corpus_one.sh.
#
# WHY IT EXISTS, measured: the serial corpus_x.sh ran at ~40 rows/min over a
# 6446-module corpus (ir-pass/test/*.ll = 2087, plus 4359 files under every
# session's track*/probes and review_*_probes), i.e. ~2.7 h. The sweep is
# embarrassingly parallel by construction — each row is its own `mktemp -d`,
# reads two READ-ONLY binaries and writes nothing shared — so `xargs -P` is the
# whole fix. ⚠ It is `nice`d and capped because other tracks build on this box;
# PROTOCOL.md's build cap is about BUILDS, and this is not one, but contention
# still causes false FAILURES (never false passes), and the rows are compared
# within themselves so a slow row is not a wrong row.
#
# Usage: ORC=<oracle root> SUBJ=<subject root> corpus_par.sh <out> [jobs]
set -u
ORC=${ORC:?}; export ORC
SUBJ=${SUBJ:?}; export SUBJ
OUT=${1:?}
JOBS=${2:-6}
HERE=$(cd "$(dirname "$0")" && pwd)

# ⚠ THE ORDER IS DELIBERATE AND IS NOT COSMETIC. The two halves are sorted
# SEPARATELY and concatenated — shipped fixtures FIRST — rather than globally
# `sort -u`'d, so that a sweep which has to be stopped early still yields a
# COMPLETE fixture half (2087 `.ll` rows, no `clang`, the population a merge
# gate actually adjudicates) instead of a uniformly partial one. A partial
# sweep is not a slow result, it is a weaker one; this at least makes the part
# that completed a self-contained statement. `sort -u` still runs within each
# half, so no file is measured twice.
{
  ls "$SUBJ"/ir-pass/test/*.ll 2>/dev/null | sort -u
  find "$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records" \
       -type d \( -name probes -o -name 'review_*_probes' \) 2>/dev/null |
    while read -r d; do find "$d" \( -name '*.c' -o -name '*.ll' \) 2>/dev/null; done |
    sort -u
} > "$OUT.list"

echo "# corpus: $(wc -l < "$OUT.list" | tr -d ' ') file(s); jobs=$JOBS"
echo "# ORACLE  $(shasum -a 256 "$ORC/build/ir-pass/cq-opt" | cut -c1-16)"
echo "# SUBJECT $(shasum -a 256 "$SUBJ/build/ir-pass/cq-opt" | cut -c1-16)"

: > "$OUT"
nice -n 5 xargs -P "$JOBS" -n 1 bash "$HERE/corpus_one.sh" < "$OUT.list" >> "$OUT"
echo DONE >> "$OUT"
echo "# rows: $(grep -c '|' "$OUT")"
