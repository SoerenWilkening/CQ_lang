#!/bin/bash
# corpus_ab.sh <ORACLE_BIN> <SUBJECT_BIN> <OUT.tsv> — A/B every ir-pass fixture.
# Compares exit code, the decline string, and the sha of the lowered IR.
# ⚠ rc is captured on the line AFTER the command, never through a pipeline.
O="$1"; SUBJ="$2"; OUT="$3"
R=/Users/sorenwilkening/Desktop/Projects/CQ_lang
: > "$OUT"
for f in "$R"/ir-pass/test/*.ll; do
  n=$(basename "$f")
  "$O" -passes=cq-lowering -S "$f" -o /tmp/fn1q.o.ll 2>/tmp/fn1q.o.err; orc=$?
  "$SUBJ" -passes=cq-lowering -S "$f" -o /tmp/fn1q.s.ll 2>/tmp/fn1q.s.err; src=$?
  omsg=$(grep -m1 -o 'cq [a-z]* lowering: [^"]*' /tmp/fn1q.o.err | cut -c1-70)
  smsg=$(grep -m1 -o 'cq [a-z]* lowering: [^"]*' /tmp/fn1q.s.err | cut -c1-70)
  osha=$([ $orc -eq 0 ] && shasum -a 256 /tmp/fn1q.o.ll | cut -c1-16 || echo "-")
  ssha=$([ $src -eq 0 ] && shasum -a 256 /tmp/fn1q.s.ll | cut -c1-16 || echo "-")
  verd="SAME"
  [ "$orc" != "$src" ] && verd=$([ $orc -ne 0 ] && echo "D->A" || echo "A->D")
  [ "$verd" = SAME ] && [ $orc -ne 0 ] && [ "$omsg" != "$smsg" ] && verd="STRING"
  [ "$verd" = SAME ] && [ $orc -eq 0 ] && [ "$osha" != "$ssha" ] && verd="STREAM"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$verd" "$orc/$src" "$osha/$ssha" "$omsg" "$smsg" >> "$OUT"
done
