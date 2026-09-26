#!/bin/bash
# corpus_ab.sh A B OUT — run cq-opt A and B over every ir-pass/test/*.ll; per-file
# record: rc, stdout sha256, first error line. Prints denominator and movers.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
A=$1; B=$2; OUT=$3
: > "$OUT"
n=0
for f in "$W"/ir-pass/test/*.ll; do
  n=$((n+1))
  ra=$("$A" -passes=cq-lowering -S "$f" -o - 2>"$OUT.ea" | shasum -a 256 | cut -c1-16); ca=${PIPESTATUS[0]}
  rb=$("$B" -passes=cq-lowering -S "$f" -o - 2>"$OUT.eb" | shasum -a 256 | cut -c1-16); cb=${PIPESTATUS[0]}
  ea=$(grep -m1 'error:' "$OUT.ea" | sed 's/.*error: //'); eb=$(grep -m1 'error:' "$OUT.eb" | sed 's/.*error: //')
  if [ "$ca" != "$cb" ] || [ "$ra" != "$rb" ] || [ "$ea" != "$eb" ]; then
    echo "MOVER $(basename "$f") A:rc=$ca,$ra,[$ea] B:rc=$cb,$rb,[$eb]" >> "$OUT"
  fi
done
echo "DENOM $n MOVERS $(grep -c ^MOVER "$OUT")" >> "$OUT"
rm -f "$OUT.ea" "$OUT.eb"
