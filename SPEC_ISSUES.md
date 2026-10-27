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

## 52_array_out_param: clone mask gives `out` one digit; CR §1.4 gives one per cell it carries
- Rule: CR §1.4 mask (a pointer-to-slot parameter contributes one digit per field it carries; only a
  pointer to a runtime-length register is one digit). 106 `__cq_q_worker_11` gives a plain `void *`
  one digit per accessed cell.
- Disagreement: `reduce(in, n, c, out)` writes `out[0]` and `out[1]` (constant cells, no handle at the
  call): by CR the clone is `__cq_q_reduce_10000`; the reference defines `__cq_q_reduce_1000`.
- Evidence: `tests/taint/check_taint.py 52`: clones missing `__cq_q_reduce_1000`, extra
  `__cq_q_reduce_10000`.
- Bead: cq-xc3

## 98_quantum_depth_recursion: cutoff uses the call-site bound B = 3, name has no `_b3`
- Rule: CR §1.4 `_bN` (one bound per quantum integer argument the call site's range facts bound; a
  clone's cutoffs use only bounds in its name and its own range facts).
- Disagreement: `chain(n & 3, a)` with `n` quantum; the reference cuts at min(K, B) = 3 from the and's
  range fact but names the clone `__cq_q_chain_10`; by CR it is `__cq_q_chain_10_b3`.
- Evidence: `tests/taint/check_taint.py 98`: clones missing `__cq_q_chain_10`, extra
  `__cq_q_chain_10_b3` (levels `_d1`..`_d3` match).
- Bead: cq-k52
