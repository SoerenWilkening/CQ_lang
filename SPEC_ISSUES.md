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

## 50 references with a rule-6 `add` or `xor` clean-up still show the form before the in-place update
- Rule: CR rule 6, *In-place update* (owner 2026-11-25): a plain `add` or `xor` of a dead value is one core gate on the old rail (`add_<W>`, `addc_<W>`, `copy_<W>`, `xorc_<W>`)
- Disagreement: the references emit the template into a fresh rail, then `t = f⁻¹(y')`, `copy(t, y_old)`, `_unc` of `t` and the free of `y_old`. Examples: 01, 02, 10, 12, 31, 32, 34, 43, 45, 59, 67, 72, 73, 77, 82, 90, 94, 95, 100, 106, 107, 108, 109, 112, 113, 114, 120, 122, 124, 125, 127, 129, 130, 136, 141, 143, 162, 165, 168, 186, 188, 191, 193, 195, 198, 203, 204, 205, 206, 212. 38, 144 and 180, where a rotation acts on the rail before and after the update, failed §6 against their reference and were rewritten in the new form on 2026-11-25.
- Evidence: the pass output for these examples differs before and after the rule (merge 6b1606216); §6 passes against the reference and the C program on every one of them (`cqcheck run --oracle both`, quick mode, 2026-11-25), so the difference is textual.
- Bead: cq-2h7xa
