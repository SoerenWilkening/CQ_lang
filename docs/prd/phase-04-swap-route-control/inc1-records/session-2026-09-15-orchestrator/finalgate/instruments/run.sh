#!/bin/bash
# run.sh <outfile> — the full ORACLE-vs-SUBJECT sweep with anti-vacuity assertions.
set -u
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/1c53d18f-fd04-48d9-8e6f-94acf28a1db2/scratchpad
OUT=$1
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_VERIFY
# ASSERTION 1: both binaries and both plugins exist and are executable.
for b in "$ORC/build/ir-pass/cq-opt" "$SUBJ/build/ir-pass/cq-opt"; do
  [ -x "$b" ] || { echo "REFUSE: missing/non-exec $b" >&2; exit 2; }
done
for p in "$ORC/build/ir-pass/libCQPass.so" "$SUBJ/build/ir-pass/libCQPass.so"; do
  [ -s "$p" ] || { echo "REFUSE: missing plugin $p" >&2; exit 2; }
done
# ASSERTION 2: the ORACLE is the frozen one.
OH=$(shasum -a 256 "$ORC/build/ir-pass/cq-opt" | cut -d' ' -f1)
[ "$OH" = "0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d" ] \
  || { echo "REFUSE: ORACLE hash moved: $OH" >&2; exit 2; }
[ -s "$T/sweep/list.txt" ] || { echo "REFUSE: empty corpus list" >&2; exit 2; }
rm -f "$OUT"
xargs -P 4 -n 1 "$T/sweep/row.sh" < "$T/sweep/list.txt" > "$OUT" 2>"$OUT.err"
# ASSERTION 3: rows exist, none is exit 127/126, and BOTH verdict classes occur.
ROWS=$(wc -l < "$OUT")
[ "$ROWS" -gt 0 ] || { echo "REFUSE: 0 rows" >&2; exit 2; }
X127=$(grep -c '|X:' "$OUT" || true)
[ "$X127" -eq 0 ] || { echo "REFUSE: $X127 rows are exit 126/127 -- the sweep measured nothing" >&2; exit 2; }
NA=$(grep -c '|A:' "$OUT" || true); ND=$(grep -c '|D:' "$OUT" || true)
[ "$NA" -gt 0 ] || { echo "REFUSE: no ACCEPT rows -- one verdict class absent" >&2; exit 2; }
[ "$ND" -gt 0 ] || { echo "REFUSE: no DECLINE rows -- one verdict class absent" >&2; exit 2; }
echo "sweep OK: rows=$ROWS  rows-with-an-accept=$NA  rows-with-a-decline=$ND  exit127=0"
