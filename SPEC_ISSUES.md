# Spec issues

Contradictions found in the pinned CQ_spec (see `spec.lock`). CONSTRUCTION_RULES.md wins over an
example; the fix lands in CQ_spec (tracked in its §7 table), never as a workaround here. An entry is
removed when the fix is in CQ_spec and `spec.lock` is re-pinned to it. Version 1 requires this list
to be empty.

Entry format:

```
## <example or CR section>: <one-line summary>
- Rule: <CR rule/section the example or text should follow>
- Disagreement: <what the reference, header or text says vs what the rule requires>
- Evidence: <checker output, input sample, line references>
- Bead: <cq-… id>
```

## Open

## 87 vs 190, 189 (CR rule 14): a pointer induction of a quantum-exit loop
- Rule: CR rule 14, quantum-dependent exit: "every carried value advances by a `select` on `a_j`";
  the loop is re-rolled "by SCEV"; rule 20 classifies by the access offset.
- Disagreement: 87 makes the walked pointer `p` a fat pointer whose idx is a carried rail advanced
  by `select`, so `s` is a QRAM. 190's `__cq_q_memcmp_00111001111_b3` computes `l = vl + j`,
  `r = vr + j` from the classical trip index (slot loads checked against the cell count), and 189
  takes its induction `i` as the trip index `j`. The same shape gets two classifications; both are
  §6-equivalent. We follow 190/189 for pointers (owner may override).
- Evidence: 87 pointer_induction.lowered.ll header ("p.idx a loop-carried rail"), 190
  memmove_memcmp_escape.lowered.ll lines 168-200 ("l = vl + j, r = vr + j (SCEV)"), 189
  heap_linked_list.lowered.ll line 36.
- Bead: cq-n7e9

## 117 (CR rule 12, §6 item 2): one phase on a disjunction vs per-edge phases
- Rule: CR rule 12: inside a `_ctl` clone `cq_phi` is `rz_i1(pred, θ)`, pred the block's predicate;
  §6 item 2 compares the rotation list gate by gate up to reordering and rail renaming.
- Disagreement: grover's O phase sits in block %38, reached from trip 0's test (%22) and, through
  the is_marked loop's exit block %34 and the join %36, from every trip's quantum exit. Rule 12 gives
  one `rz_i1` on the flag of pred(%38) (our lowering). The reference emits one `rz_i1` per path: on the
  trip-0 edge flag in %22's lowering and on `a_k & %33` inside each trip. Equal on every basis branch
  (the edge predicates are disjoint), but one gate on f1|f2 matches neither gate on f1 nor on f2 in
  §6's gate-by-gate list, so 117 fails s6 against the reference while it passes the C oracle.
- Evidence: cqcheck run 117_qpe_counting --oracle both (branch cq-r8-e117): c=pass, verifier=pass,
  s6=fail "our gate #68 phase(f=413, 0x400921fb54442d18) (predicate 0000011) matches no reference
  gate movable to this position" (nq=3, t=5, mk1; t=6: gate #73). qpe_counting.lowered.ll
  __cq_q_grover_1000_ctl blocks 24 and 35 (the two rz_i1 on edge flags).
- Bead: cq-u2mw
