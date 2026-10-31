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

## 169_complex_div / 173: reference helper bodies vs the pinned musl and compiler-rt sources
- Rule: CR rule 18 (an injected body is lifted with full knowledge of that body); the injection bundle's pins.
- Disagreement: 169 lifts musl logb with ilogb inlined and FORCE_EVAL(0/0.0f) as no gate; pinned musl ilogb.c has `#pragma STDC FENV_ACCESS ON` (strictfp, not inlined, INVALID raised under a quantum predicate). compiler-rt 19.1.7's *c3 bodies use inline __compiler_rt_logb/scalbn/fmax, which no example witnesses.
- Ruling (owner, 2026-10-29): an example's .c is normative for every function it defines (169 __divdc3, 173 __mulsc3/__divsc3 stay; a user definition shadows the bundle's). For functions the .c does not define the pinned source as built is normative: 169 is regenerated with a __cq_q_ilogb_1 clone on 82's fenv ABI. A new §8 example witnesses the real compiler-rt *c3 bodies. Our side: cq-yiwy.
- Bead: cq-ezan

## 136_callee_measure: cq_measure(y) of a value rule 2 collapsed is emitted as a measurement
- Rule: CR rule 2 at b3d3206 ("Collapse is a data-flow condition, not a program-order one: a rail computed *before* the measurement of its only quantum source collapses too ... A `cq_measure` of a value this rule made classical is a classical read and emits no measurement.")
- Disagreement: callee_measure computes y = x + c (c classical), then readout(x, k) measures x's rail inside the clone, then `cq_measure(y)`. y's only quantum source is measured, so the reference's `cqrt_measure_i32(%6)` (y) should be a classical read with no measurement. The header itself says x's measurement "collapses ... through y = x + c, the entangled y".
- Evidence: `cqcheck run 136_callee_measure --oracle both` on branch cq-y1ll (C oracle counts a measure only for a non-collapsed operand): s6 pass, c fail "our measurement(s) [1] (rails [2]) match no C measurement". Same shape likely in 102 raise_handled (hit = select(x > k, s, seed), measured after x); 102 does not lower today (eff-tape unimplemented), not checked.
- Expected form (orchestrator decision on cq-ihlt, for the regeneration): the caller re-reads x's rail (`cqrt_measure` on the already-measured rail, a classical re-read per rule 2), uncomputes and frees y's rail at the collapse point, and recomputes y = m_x + c classically; `cq_measure(y)` emits nothing. If the regenerated reference chooses another channel we follow it.
- Bead: cq-9hwg

## Entry returning a quantum value narrower than i32 (976_u06 probe, no corpus example)
- Rule: CR rule 19 (an entry returning an unmeasured quantum value "keeps its C signature and returns the handle") vs §1.1 (every quantum value is an `i32` handle; narrow handle arguments at externally visible signatures widen with the C ABI's zeroext/signext).
- Gap: for `_Bool`, `char` or `short` returns (IR `i1`/`i8`/`i16`) the C signature cannot hold the `i32` handle; truncating it returns another rail's handle. CR does not say whether the entry's return widens to `i32` (as §1.1 does for arguments), is measured, or is outside the language. 161 and 162 return `i32`.
- Ours meanwhile: `cq::unimplemented` (orchestrator decision under §1.1, rule 19 and principle 2); `i64` returns stay a zext of the handle.
- Bead: cq-juf6
