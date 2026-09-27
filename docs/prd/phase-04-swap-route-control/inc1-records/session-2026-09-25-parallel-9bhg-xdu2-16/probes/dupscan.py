#!/usr/bin/env python3
"""L8 duplicate-body scan: sha-256 over each ir-pass/test/*.ll's non-comment lines;
print every group of files sharing a body that includes one of this change's
fixtures (and the total group count for context)."""
import collections
import hashlib
import pathlib

T = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/ir-pass/test")
MINE = {
    "taint_accept_spec_classical_return.ll", "taint_accept_spec_classical_return_arith.ll",
    "taint_accept_spec_classical_return_branch.ll", "taint_accept_spec_classical_return_clone_arg.ll",
    "taint_reject_spec_quantum_return_measure.ll", "taint_reject_spec_quantum_return_branch.ll",
    "taint_reject_quantum_return_mixed_spec.ll", "taint_reject_quantum_return_spec_seeded_theta.ll",
    "taint_reject_quantum_return_mixed_rets.ll", "taint_reject_scrubbed_handle_clone_arg.ll",
    "taint_reject_scrubbed_handle_clone_arg_mixed.ll", "taint_reject_scrubbed_handle_clone_arg_layout.ll",
    "spec_accept_fp_rebuilt_site_second_clone.ll",
    "taint_reject_quantum_return_lift_owner_order.ll",
    "taint_accept_spec_classical_return_round2.ll",
    "spec_accept_ordered_scrub_lift_mixed_mask.ll",
}
groups = collections.defaultdict(list)
for f in sorted(T.glob("*.ll")):
    body = "\n".join(l for l in f.read_text(errors="replace").splitlines()
                     if not l.lstrip().startswith(";") and l.strip())
    groups[hashlib.sha256(body.encode()).hexdigest()].append(f.name)
dups = [g for g in groups.values() if len(g) > 1]
print(f"{sum(len(g) for g in groups.values())} fixtures, {len(dups)} duplicate-body group(s) in the corpus")
for g in dups:
    if MINE & set(g):
        print("  INVOLVES THIS CHANGE:", g)
print("fixtures of this change present:", len(MINE & {n for g in groups.values() for n in g}), "of", len(MINE))
