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

## 107 (CR rule 21): a triple formal the callee loads through, passed without its cell count
- Rule: CR rule 21: "when the callee loads through the pointer, the object's cell count follows the
  triple as a compiler-added `i32` (no mask digit, 190)".
- Disagreement: 107's union_slot passes `&u` to `bump`, which loads `u->v` through it, as
  `@__cq_q_bump_0011(ptr %6, i32 3, i32 0)`: no cell count (and the twin takes `(ptr, i32, i32, old
  tag, old idx)`). We follow CR: the cell count 1 follows the triple (the record is one cell). Signatures
  are not compared by §6, so the verdict does not depend on it.
- Evidence: pointer_int_union.lowered.ll, union_slot's call of `@__cq_q_bump_0011` and the header
  ("NO object table is passed").
- Bead: cq-47n3
