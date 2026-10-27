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

None.

## CR §3 rule 27: no witness examples named
- Rule: CR §3 preamble, "Each rule names its witness examples."
- Disagreement: rule 27 has no witness clause ("— NN, …"); examples 161 and 190 list rule 27 in their Rules: headers and CR §7's last row names them for rule 27.
- Evidence: `python3 -m cqcheck progress` (from checker/) lists "27 Callees without a body: declared clones" with no witnesses; CONSTRUCTION_RULES.md lines 554-599.
- Bead: cq-48r
