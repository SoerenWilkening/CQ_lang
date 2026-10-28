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

## Rule-6 population, pending CQ_spec §7
- Rule: CR rule 6 at CQ_spec 509e6ed (owner ruling cq-qpsb): every dead old value under a bijective update is cleaned.
- Done at 7617dcb: 01, 02, 10, 12, 13, 43, 45, 94, 108, 109, 112, 156, 162, 186 rewritten; our lowering of 01, 02, 10, 12, 13, 43, 156 is green against them.
- Still open on the CQ_spec side (CR §7 row): the loop chains in 05, 09, 26, 27, 54, 68, 73, 75, 91, 139, 149, 150; the selects in 100, 116, 123, 129; 190 memmove_overlap. Our pass does not lower these yet.
- Bead: cq-qpsb

## 65_fenv_bracket: fenv_tested measures a value rule 2 makes classical
- Rule: CR rule 2, classical collapse: a value computed only from measured rails and classical values is classical (rail uncomputed, value recomputed classically).
- Disagreement: fenv_tested measures y, then f = fetestexcept(FE_INEXACT) = host | (select(y > k, 32, 0) & 32), which depends only on the measured y and the host flags. The reference keeps and measures f's rail (`cqrt_measure_i32(%13)`); rule 2 makes f classical, so cq_measure(f) is a classical re-read and no second measurement exists.
- Evidence: `cqcheck run 65_fenv_bracket --oracle both` with our lowering (f collapsed): s6 and C oracle fail on every sample, "1 measurements != 2".
- Bead: cq-r6bc
