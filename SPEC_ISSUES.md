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

## §1.4, rule 2, 211: `_t` measures the argument rail itself
- Rule: §1.4 "in the clone without a predicate the outcome is classical and is returned as a seed rail like any classical result (211)"; rule 2 (the measured rail stays allocated); 211 lines 178-182 (`__cq_q_peek_1_t`: "the argument rail is measured"); rule 18 "no measured rail is ever gated"; rule 19 "The caller has no record of the callee". CQ_spec 4d08ffa did not change these.
- Contradiction: for a call through a classical pointer whose actual is a garbage rail, a `_t` measuring its formal measures the caller's rail, and the caller, with no record of the callee, uncomputes and frees it. Rule 19 plus rule 18 make that unlowerable. Probe: `int in(int x){ return cq_measure(x)+1; }` called as `p(a+1)`: `cqrt_free: rail 2 is a measured rail` (tests/calls/probes/meas_table_t.c).
- Ours: `_t` measures a kept copy, `t = alloc_W(0); copy_W(h, t); o = measure_W(t)`. `h` is untouched and the caller uncomputes and frees it as today. Everything else is the text: the outcome is classical, returned as a seed rail, and rule 18 (4d08ffa) leaves `_t` its twin, which zeroes and frees a rail result and leaves the seed allocated. `_t` pushes `t`, a rail it minted (§1.4), and `_t_unc` pops it and re-reads it (rule 2), so no second measurement is made. A by-name callee that measures its formal gets such a copy from `_t` too. A copy per trip of a loop leaves `_t` no twin, as a rotation per trip does. `__cq_q_peek_1_t` in 211 is not copied; 211 does not reach it at run time, so no verdict depends on it.
- Request: §1.4, rule 2 and 211 to say `_t` measures a copy of its formal, or to rule otherwise.
- Bead: cq-t2jj2
