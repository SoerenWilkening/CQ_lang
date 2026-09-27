#!/bin/bash
set -e
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/merge12/respell9.py
for f in taint_accept_spec_classical_return taint_accept_spec_classical_return_arith \
  taint_accept_spec_classical_return_branch taint_accept_spec_classical_return_clone_arg \
  taint_reject_scrubbed_handle_clone_arg taint_reject_scrubbed_handle_clone_arg_mixed \
  taint_reject_scrubbed_handle_clone_arg_layout taint_reject_quantum_return_mixed_spec \
  taint_reject_quantum_return_spec_seeded_theta taint_reject_quantum_return_mixed_rets; do
  python3 "$R" "$W/ir-pass/test/$f.ll" h
done
python3 "$R" "$W/ir-pass/test/taint_reject_quantum_return_lift_owner_order.ll" hc
