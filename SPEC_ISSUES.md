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

## 168_*: the reference folds an offset that follows a quantum index into the address literal
- Rule: CR rule 20, address literals (the offsets after the first quantum index are added on the index side)
- Disagreement: the reference lowering passes `base + 4` as the `_hl` literal of an access `arr[q].field`; the rule gives `add_i64_hl(rail, 4)` and then the literal `base`. 120 and 129 have the same shape.
- Evidence: textual diff of the pass output against the reference for 168 (pass since cq-3v6fh); the §6 verdict is pass on all three.
- Bead: cq-dnip9

## 34, 67, 72, 90, 106: the pass updates in place where the reference applies no rule 6
- Rule: CR rule 6, *In-place update* (owner 2026-11-25), and rule 6's trigger: a call result with a twin and a value whose operands are both garbage are not cleaned by this rule
- Disagreement: the pass emits `add_<W>`/`addc_<W>` in place on a clone result that has an `_unc` twin (34, dropping the twin call), on the bump clone's result (67, the reference's SPEC GAP note), on a zext template result of two load copies (72, 90) and on a dead `mul` template result (106). The references keep those values as garbage and were left as they are.
- Evidence: §6 passes against the reference and the C program on all five (2026-11-26). The other references with a covered site (33 files) were rewritten in the in-place form on 2026-11-26; 165 now cleans the sext rail by rule 6 where the old reference uncomputed the cast.
- Bead: cq-58gzf
