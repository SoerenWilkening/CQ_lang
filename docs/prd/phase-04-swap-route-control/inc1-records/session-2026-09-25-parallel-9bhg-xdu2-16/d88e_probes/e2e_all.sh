#!/bin/bash
# e2e_all.sh : the three new d88e slices on the ORACLE and on the SUBJECT, then
# cross-diffs (oracle vs subject per slice; 2-TU vs twin per binary).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440
T="$S/d88e/e2e_trace.sh"
E="$W/tests/e2e"
for v in ora new; do
  if [ "$v" = new ]; then B="$S/frozen/cq-opt.d88e_v1"; else B="$S/frozen/cq-opt.main_e846"; fi
  echo "##### $v quantum";   bash "$T" "$B" "$S/d88e/e2e/q_$v" "$E/slice_spec_lift_quantum_base.c" "$E/spec_lift_quantum_lib.c"
  echo "##### $v elsewhere"; bash "$T" "$B" "$S/d88e/e2e/e_$v" "$E/slice_spec_lift_scrubbed_elsewhere.c" "$E/spec_lift_classical_lib.c"
  echo "##### $v twin";      bash "$T" "$B" "$S/d88e/e2e/t_$v" "$E/slice_spec_lift_scrubbed_elsewhere_twin.c"
done
echo "##### diffs"
for s in q e t; do
  if cmp -s "$S/d88e/e2e/${s}_ora/trace.log" "$S/d88e/e2e/${s}_new/trace.log"; then echo "$s: ora == new"; else echo "$s: ora != new"; fi
done
for v in ora new; do
  if cmp -s "$S/d88e/e2e/e_$v/trace.log" "$S/d88e/e2e/t_$v/trace.log"; then echo "$v: 2-TU == twin"; else echo "$v: 2-TU != twin"; fi
done
