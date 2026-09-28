#!/bin/bash
# Round 2 (F-r1B-6): the independent-witness pairs. Each z0re runtime slice vs its
# spelling through PRE-EXISTING cleared code; the cleared spelling is run on the
# frozen ORACLE (and on the subject), and every trace is compared.
# usage: indep.sh <subject cq-opt>
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
ORA=$S/frozen/cq-opt.main_9a230646
SUB=$1
T1=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/z0re_probes/trace1.sh
E=$W/tests/e2e
O=$(mktemp -d)
run() { bash "$T1" "$1" "$2" > "$3"; }
run "$ORA" "$E/slice_z0re_runtime_seed_prep_literal.c" "$O/lit.ora"
run "$SUB" "$E/slice_z0re_runtime_seed_prep_literal.c" "$O/lit.sub"
run "$SUB" "$E/slice_z0re_runtime_seed_prep.c" "$O/rt.sub"
run "$ORA" "$E/slice_z0re_runtime_seed_prep.c" "$O/rt.ora"
run "$ORA" "$E/slice_z0re_angle_select_runtime_base_exact_inplace.c" "$O/inp.ora"
run "$SUB" "$E/slice_z0re_angle_select_runtime_base_exact_inplace.c" "$O/inp.sub"
run "$SUB" "$E/slice_z0re_angle_select_runtime_base_exact.c" "$O/ex.sub"
run "$ORA" "$E/slice_z0re_angle_select_runtime_base_exact.c" "$O/ex.ora"
for f in lit.ora lit.sub rt.sub rt.ora inp.ora inp.sub ex.sub ex.ora; do
  echo "== $f: $(head -1 "$O/$f" | cut -c1-160)  lines=$(wc -l < "$O/$f" | tr -d ' ')"
done
cmpt() { if cmp -s <(tail -n +2 "$O/$1") <(tail -n +2 "$O/$2"); then echo "IDENTICAL  $1 vs $2"; else echo "DIFFERENT  $1 vs $2"; fi; }
cmpt lit.ora rt.sub
cmpt lit.ora lit.sub
cmpt inp.ora ex.sub
cmpt inp.ora inp.sub
echo "== golden check"
if cmp -s <(tail -n +2 "$O/rt.sub") "$E/slice_z0re_runtime_seed_prep.expected.log"; then echo "rt.sub == committed golden"; else echo "rt.sub != committed golden"; fi
tail -n +2 "$O/ex.sub"
rm -rf "$O"
