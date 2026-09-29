#!/bin/bash
# cmp.sh BIN SUBJ.ll TWIN.ll [args] : verdict + trace identity (subject vs its hand-inlined twin, same binary)
R=$(dirname $0)
a=$(bash $R/run.sh $1 $2 ${4:-5}); b=$(bash $R/run.sh $1 $3 ${4:-5})
echo "--- S: $(echo "$a" | head -3 | tr '\n' ' ')"
echo "--- T: $(echo "$b" | head -3 | tr '\n' ' ')"
ta=$(echo "$a" | grep -v "^opt\|^run\|free_pairing\|error\|warning"); tb=$(echo "$b" | grep -v "^opt\|^run\|free_pairing\|error\|warning")
if echo "$a" | grep -q "opt rc=0" && echo "$b" | grep -q "opt rc=0"; then
  if [ "$ta" == "$tb" ]; then echo "TRACE-IDENT ($(echo "$ta" | wc -l | tr -d ' ') lines)"; else echo TRACE-DIFF; diff <(echo "$ta") <(echo "$tb"); fi
else echo "VERDICT: S=$(echo "$a"|head -1) T=$(echo "$b"|head -1)"; fi
