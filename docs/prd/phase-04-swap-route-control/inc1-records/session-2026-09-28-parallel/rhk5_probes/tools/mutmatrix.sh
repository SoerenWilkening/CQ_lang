#!/bin/bash
# mutmatrix.sh FILTER NAME... : run lit (the scratch site config) with each mutant's
# cq-opt + cq-opt-debugalloc over the fixtures matching FILTER; print the denominator
# and the failing fixtures. FILTER "ALL" runs the whole suite.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
F=$1; shift
cd "$S" || exit 1
for n in "$@"; do
  if [ "$F" = ALL ]; then flt=(); else flt=(--filter "$F"); fi
  out=$(RHK5_CQ_OPT="$S/bin/cq-opt.$n" RHK5_DEBUGALLOC="$S/bin/cq-opt-debugalloc.$n" \
        lit -j4 --timeout 120 litora "${flt[@]}" 2>&1)
  disc=$(echo "$out" | grep -E "Total Discovered|Excluded" | tr -s ' ' | tr '\n' ' ')
  fails=$(echo "$out" | grep -E "^(FAIL|TIMEOUT|UNRESOLVED): " | sed 's/.*:: //; s/ (.*//' | tr '\n' ' ')
  nf=$(echo "$out" | grep -cE "^(FAIL|TIMEOUT|UNRESOLVED): ")
  echo "$n | $disc| failed=$nf | $fails"
done
