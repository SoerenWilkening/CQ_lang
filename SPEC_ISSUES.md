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

- eff-invert (cq-4593, cq-asfn): "A cq_invert marker under a quantum predicate" — clang -O1 duplicates __cq_invert_begin/_end into both arms of a quantum branch (IR tests/eff-invert/probes/dup_begin_error.O1.ll, blocks %8/%9 each hold a begin); linearized, both run: two begins for one end. Where does the region start/end?
- loops-cutoff (cq-8i5g): a computed goto whose address does not come from a constant table read, a select or a constant (a carried phi of block addresses, or stored to memory and loaded back): rule 13 says "the integer the target address was derived from" but not how to find it through memory or a carried phi.
- mem-qram (cq-pf4n): a QRAM over an extern object of unknown extent whose initial contents are its definer's (@g = external global [0 x i32], store at a quantum offset): no form seeds cells from host memory the compiler cannot bound.
