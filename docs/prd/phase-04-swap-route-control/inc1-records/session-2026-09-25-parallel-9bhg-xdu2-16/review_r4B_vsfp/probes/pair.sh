#!/bin/bash
# pair.sh a b : compare traces of a (SUBJ/NOFREE/LIFO) vs b.SUBJ
a=$1; b=$2
for t in SUBJ NOFREE LIFO; do
  if [ -f out/$a.$t.trace ] && [ -f out/$b.SUBJ.trace ]; then
    if diff -q out/$a.$t.trace out/$b.SUBJ.trace >/dev/null; then echo "$a.$t vs $b.SUBJ: TRACE-IDENT"; else echo "$a.$t vs $b.SUBJ: TRACE-DIFF"; fi
  else echo "$a.$t vs $b.SUBJ: (no trace pair)"; fi
done
