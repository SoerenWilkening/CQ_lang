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

## 163_struct_return_sret: slot results stored without the rule 18 copy-out
- Rule: CR rule 18 ("copies each result into a fresh rail ... a one-template body may return its rail directly"), as 31_pointer_out_param does for a slot result.
- Disagreement: __cq_q_mk_00010 (two templates) stores its template rails into the sret cells directly and its twin undoes them in place; the header cites 31 for "no copy-out", but 31 copies out (alloc + copy, store of the copy) and its twin XORs the copy out.
- Evidence: 163 lowered.ll lines 45-63 and header lines 7-17; 31 lowered.ll __cq_q_split_100 and __cq_q_split_100_unc.
- Bead: cq-svyn

## 94_atomics: the reference cleans x by rule 6 though x is read after its update
- Rule: CR rule 6, Dead ("nothing reads the old value after the update: no SSA use ...").
- Disagreement: the update is `old = atomicrmw add cell, c` (x' = x + c, its result is the old value x); the cmpxchg reads
  old afterwards as its new value (select(f, old, cell)). The reference header cleans x ("rule 6: dead after the cmpxchg
  select, its last reader") and keeps only x + c, the select and the flag; under the Dead clause x is not dead at the
  update, so it stays the user register (kept).
- Evidence: `cqcheck run 94 --oracle both` on branch cq-w2a-mem-slots: s6 fail, "1 rail(s) i32 ... kept on our side that
  the reference does not keep"; C oracle pass; verifier pass.
- Bead: cq-k7f8
