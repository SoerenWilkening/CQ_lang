#!/usr/bin/env bash
# pairs.sh "<subj> <twin>" ... : run subject on main/9bhg/sub (+ any extra tags in $TAGS), twin on sub; compare traces
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1Bv
cd $S
TAGS=${TAGS:-"main 9bhg sub"}
ARGS=${ARGS:-"5 7"}
TT=${TT:-sub}
for p in "$@"; do
  set -- $p
  a=$1; b=$2
  rm -f out/$b.$TT.trace
  bash h.sh $TT $b $ARGS | head -1
  for t in $TAGS; do
    rm -f out/$a.$t.trace
    line=$(bash h.sh $t $a $ARGS | head -1)
    if [ -f out/$a.$t.trace ] && [ -f out/$b.$TT.trace ]; then
      if cmp -s out/$a.$t.trace out/$b.$TT.trace; then cmpres="TRACE-IDENT"; else cmpres="TRACE-DIFF"; fi
    else cmpres="-"; fi
    echo "$line  <$cmpres>"
  done
done
