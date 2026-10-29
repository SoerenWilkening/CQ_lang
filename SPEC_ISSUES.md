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

## 80, 81, 100: rule 27's exception list omits rule 23
- Rule: CR rule 27 ("The compiler knows no library by name ... except the calls rule 16, rule 22 and the intrinsic routes classify"); rule 23 ("fenv calls on quantum state are rail operations").
- Disagreement: the references of 80, 81 and 100 lower fesetround/fetestexcept/feraiseexcept/... on quantum state as rail operations, which needs recognising <fenv.h> calls by name; rule 27 read literally makes a quantum call to a bodiless fesetround a declared clone.
- Evidence: 80_fenv_rounding.lowered.ll (fesetround on a quantum mode), 81, 100; our pass follows rule 23 and is §6-green on all three.
- Bead: cq-8q9i

## 26_break_quantum_cond: break_with_body keeps the |1> trip seed on the zero-trip path
- Rule: CR rule 14, classical bound with a quantum exit ("every predicate, the last included, ... is uncomputed by the mirror. Nothing is kept."); rule 7 (a seed is freed directly).
- Disagreement: the reference allocates `%8 = cqrt_alloc_i1(i1 true)` (the trip-0 predicate) in the entry, before the classical branch on `n < 1`; the skip block `%10` measures `%7` and returns without freeing `%8`, so a |1> seed is live at exit whenever n < 1.
- Evidence: `cqcheck run 26_break_quantum_cond --oracle both` (cq-174f with cq-t71u's patch): c=pass, verifier=pass, s6 fails on n = 0 only: "1 rail(s) i1 with values 1 the reference keeps are not kept on our side".
- Bead: cq-ph2i

## 22_switch_quantum: switch_phase expands a quantum-chosen phase angle into per-case phases
- Rule: CR rule 11 ("An angle that depends on quantum data in any way (a `select` or `phi` on a quantum flag, a `switch` over a quantum scrutinee, ...) is computed into an `f64` rail ... and consumed by rule 15's single primitive. The compiler never expands it into per-arm controlled rotations.")
- Disagreement: in switch_phase, -O1 merges the three case phases into one `cq_phi(%12)` in the shared case block `%11`, `%12 = phi double [ %4, %9 ], [ %3, %8 ], [ %2, %5 ]`, chosen by the quantum switch on `x & 3`. The reference emits `rz_i1(case flag, pK)` per case (rule 13, "phase arms per rule 8"); rule 11 requires one `rz_qangle[_controlled]` on a select rail.
- Evidence: `cqcheck run 22_switch_quantum --oracle both` with cq-bxc4 (taint marks `%12` quantum): c=pass, verifier=pass; s6 fails in switch_phase only, "our gate #1 phase_qangle(rail 6, ctl=[7]) matches no reference gate"; switch_value passes.
- Bead: cq-5h88

## 125_mixed_phase_value_arm vs 133_state_prep_overwrite: rule 10's controlled Ry sits on opposite sides of the sibling arm's phase
- Rule: CR rule 10 (no position given for the prep's `ry_<W>_controlled`); CR §6 item 2 ("an Ry is ordered against every gate it overlaps").
- Disagreement: the same shape (a prep under the flag f in one arm, a `cq_phi` in the other arm, one merge phi) is ordered both ways. 133 prep_beside_phase emits `xorc`/`ry_i32_controlled(f, r)` in the arm, before `not; rz_i1(f, p); not`. 125 emits `ry_i32_controlled(f, r)` at the merge phi %19, after `not; rz_i1(f, b); not`. The Ry's control f is the phase's support, so §6 orders them, and no placement rule for the construction meets both references.
- Evidence: the current lowering (Ry at the prep in its arm) passes 133 and fails 125 (`cqcheck run 125_mixed_phase_value_arm --oracle both`: "our gate #3 ry(h=5, ..., ctl=[3]) ... matches no reference gate movable to this position"). Our 133 lowering with xorc+Ry moved after the else-arm phase (the merge placement) fails 133 (`cqcheck run 133_state_prep_overwrite --ours ...`: "our gate #1 phase(f=2, 0x3fb999999999999a) ... matches no reference gate movable to this position").
- Bead: cq-vrwm
