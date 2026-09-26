#!/bin/bash
# cmp.sh a b : compare SUBJ traces of a and b (and show)
for t in SUBJ MAIN; do
  if [ -f out/$1.$t.trace ] && [ -f out/$2.SUBJ.trace ]; then
    if diff -q out/$1.$t.trace out/$2.SUBJ.trace >/dev/null; then echo "$1.$t vs $2.SUBJ: TRACE-IDENT"; else echo "$1.$t vs $2.SUBJ: TRACE-DIFF"; fi
  fi
done
