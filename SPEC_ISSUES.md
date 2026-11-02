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

- mem-slots (cq-05pa): 67_static_global_slot's reference frees the rail still held in @saved at exit, but rule 20 (b137e75) says rails a global's cells hold at exit are kept. Which wins? (We keep 67's lowering for that confined shape meanwhile.)
- rule 17 (cq-z7hz): an end in each arm of a quantum branch, both closing a region begun before the branch (and the same for two begins). Every C path pairs, but the host runs both calls; the rule does not say how they merge.
- rule 20 (cq-z7hz): a global QRAM of unknown extent whose element has several columns: qram_alloc_host has no strided form.
- rule 13 (cq-zaes): LLVM LangRef treats equality tests between label addresses as UB(?), yet rule 13 compares the address to ptrtoint(blockaddress). We keep it sound by giving every address-taken block a distinct, reachable stand-in with code. Confirm the reading.
