#!/bin/bash
# For every 9bhg fixture: does the vsfp dead-argument drop fire on the merged binary?
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
B=$W/build/ir-pass/cq-opt
for f in taint_accept_spec_classical_return taint_accept_spec_classical_return_arith \
  taint_accept_spec_classical_return_branch taint_accept_spec_classical_return_clone_arg \
  taint_reject_scrubbed_handle_clone_arg taint_reject_scrubbed_handle_clone_arg_mixed \
  taint_reject_scrubbed_handle_clone_arg_layout taint_reject_spec_quantum_return_measure \
  taint_reject_spec_quantum_return_branch taint_reject_quantum_return_mixed_spec \
  taint_reject_quantum_return_spec_seeded_theta taint_reject_quantum_return_mixed_rets \
  taint_reject_quantum_return_lift_owner_order spec_accept_fp_rebuilt_site_second_clone; do
  out=$(CQ_DEADARG_DBG=1 "$B" -passes=cq-lowering -S "$W/ir-pass/test/$f.ll" -o /dev/null 2>&1)
  rc=$?
  d=$(printf '%s\n' "$out" | grep -c CQ_DEADARG_DBG)
  e=$(printf '%s\n' "$out" | grep -o 'error: .*' | head -1 | cut -c1-110)
  printf '%-52s rc=%s drops=%s %s\n' "$f" "$rc" "$d" "$e"
  printf '%s\n' "$out" | grep CQ_DEADARG_DBG | sed 's/^/      /'
done
