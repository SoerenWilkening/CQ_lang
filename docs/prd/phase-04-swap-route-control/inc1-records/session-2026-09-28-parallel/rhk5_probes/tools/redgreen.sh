#!/bin/bash
# redgreen.sh FILTER TAG... : run the lit fixtures matching FILTER through the scratch
# lit site config, once per binary tag in scratch bin/ (cq-opt.<TAG> +
# cq-opt-debugalloc.<TAG>), printing PASS/FAIL per fixture.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
F=$1; shift
cd "$S" || exit 1
for b in "$@"; do
  echo "== $b"
  RHK5_CQ_OPT="$S/bin/cq-opt.$b" RHK5_DEBUGALLOC="$S/bin/cq-opt-debugalloc.$b" \
    lit litora --filter "$F" 2>&1 | grep -E "^(PASS|FAIL|UNRESOLVED)" | sed 's/CQ IR-pass :: //; s/ (.*//' | sort
done
