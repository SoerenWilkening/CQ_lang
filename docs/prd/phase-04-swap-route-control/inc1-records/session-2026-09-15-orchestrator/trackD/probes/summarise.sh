#!/bin/bash
# Track D — turn `bbu0_measure.sh`'s rows into the table MEASUREMENT.md carries.
# Deliberately prints EVERY bucket including the empty ones: a bucket that is
# absent from a summary reads as "did not happen", and a bucket that is present
# with a 0 reads as "was looked for and did not happen". Only the second is a
# measurement.
# Usage: summarise.sh <measure-out.txt>
M=$1
echo "rows: $(grep -c '|' "$M" | tr -d ' ')  (DONE marker excluded below)"
for b in WARNED SILENT PREEMPTED CRASH INSTRUMENT-BROKEN CONTROL-BROKEN CLANGERR; do
  printf '%-18s %s\n' "$b" "$(grep -c "|$b|" "$M")"
done
echo
echo "— distinct PROGRAMS (a probe committed as both .c and .s1.ll is ONE program) —"
sed 's/\.s1\.ll$//; s/\.c$//; s/\.ll$//' <(cut -d'|' -f1 "$M" | grep -v '^DONE') \
  | sort -u | wc -l
echo
echo "— non-WARNED rows in full —"
grep -vE '\|WARNED\|' "$M" | grep '|' || echo "(none)"
