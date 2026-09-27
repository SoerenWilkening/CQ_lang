#!/bin/bash
# Red/green of taint_reject_quantum_return_lift_owner_order.ll across the frozen binaries.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
F=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/ir-pass/test/taint_reject_quantum_return_lift_owner_order.ll
for b in new3 main_ba80 main983 merged; do
  bash "$S/merge9/fixture_on.sh" "$S/frozen/cq-opt.$b" "$F" "--implicit-check-not=quantum value returned"
done
