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
