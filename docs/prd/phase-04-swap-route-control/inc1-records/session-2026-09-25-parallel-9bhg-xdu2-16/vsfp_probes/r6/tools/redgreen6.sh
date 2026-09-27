#!/bin/bash
# redgreen6.sh : the one new round-6 fixture through the scratch lit site config on the ORACLE,
# round 4, round 5 and round 6 (each with its own debugalloc where one exists).
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
cd "$V" || exit 1
for T in "main:$V/../frozen/cq-opt.main_aee8:$V/bin/cq-opt-debugalloc.r6a" \
         "r4keep:$V/bin/cq-opt.r4keep:$V/bin/cq-opt-debugalloc.r4keep" \
         "r5keep:$V/bin/cq-opt.r5keep:$V/bin/cq-opt-debugalloc.r5keep" \
         "r6a:$V/bin/cq-opt.r6a:$V/bin/cq-opt-debugalloc.r6a"; do
  IFS=: read -r tag bin da <<< "$T"
  touch "$da"
  r=$(VSFP_CQ_OPT="$bin" VSFP_DEBUGALLOC="$da" lit litora --filter "musttail_inner_slot" 2>&1 | grep -E "^(PASS|FAIL)" | cut -c1-80)
  echo "$tag: $r"
done
