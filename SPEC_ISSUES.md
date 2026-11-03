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

(none; the 2026-11-03 CQ_spec commit 34c1df7 answered 87 vs 190/189 (rule 14 affine induction, 87 owed a regeneration), 67 vs rule 20 (confined static is a rule-31 slot), rule 17 every-arm markers, rule 20 strided qram_alloc_host, rule 13 label-address compare)

