#!/bin/bash
# mut_multidef.sh NAME... : run lit (-j2) with each mutant over the MULTI-FUNCTION
# fixtures OUTSIDE the §6.1 subset (a single-`define` fixture builds no clone, so
# `cloneCallPreservesArg` can only return true where a callee body exists — the
# subset ∪ this complement is exhaustive for the predicate's reach). Controls: run
# `subject_v2` first (must fail 0).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
FLT=$(cat "$S/multidef_filter.txt")
cd "$S" || exit 1
for n in "$@"; do
  out=$(RHK5_CQ_OPT="$S/bin/cq-opt.$n" RHK5_DEBUGALLOC="$S/bin/cq-opt-debugalloc.$n" \
        LIT_FILTER="$FLT" lit -j2 --timeout 120 litora 2>&1)
  disc=$(echo "$out" | grep -E "Total Discovered|Excluded" | tr -s ' ' | tr '\n' ' ')
  fails=$(echo "$out" | grep -E "^(FAIL|TIMEOUT|UNRESOLVED): " | sed 's/.*:: //; s/ (.*//' | tr '\n' ' ')
  nf=$(echo "$out" | grep -cE "^(FAIL|TIMEOUT|UNRESOLVED): ")
  echo "$n | $disc| failed=$nf | $fails"
done
