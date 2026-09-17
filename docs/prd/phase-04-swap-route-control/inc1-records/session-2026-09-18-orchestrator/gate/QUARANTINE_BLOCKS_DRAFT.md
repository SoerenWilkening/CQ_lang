# Quarantine block text for the 15 new divergences — TWO groups, DIFFERENT class/owner

⚠ Signatures are left as `<FRESH>` here and are filled in from the PASS-2 matrix run only.
⚠ A single blanket row over all 15 would mis-describe whichever group it did not come from.

---

## GROUP C-1 — 12 cells, bd `test_C_libtooling-drbq.12` (Track D's P4 widening)

```
cell     m_none_eq_none
cell     m_none_eq_none_postmark
cell     m_none_eq_none_premark
cell     m_none_eq_none_bodyread
cell     m_none_gt_none
cell     m_none_eq0_none
cell     m_none_eq_rz
cell     m_none_eq0_rz
cell     m_none_gt_rz
cell     m_rz_eq_none
cell     m_rz_eq0_none
cell     m_rz_gt_none
class    PER-TRIP FLAG MINT vs -O1 CSE. The ROLLED side mints a FRESH flag every
         trip -- a real cq_template_icmp_* + cqrt_rz_i1 + _unc strip + cqrt_free per
         repetition. The UNROLLED twin's two textually identical compares are CSE'd
         by clang -O1 into ONE flag, with the repetitions' rz stacked on it
         (cqrt_x-bracketed where the arm is the not-flag one). Owner ruling S3
         (2026-09-17) names exactly this: "rolled emits a real compare+strip every
         trip, -O1 folds the flat twin's; same unitary".
bd       test_C_libtooling-drbq.12
owner    NEITHER SIDE IS DEFICIENT. The flag is DIAGONAL, minted from the SAME
         predicate on both sides and stripped to |0> on both, so the accumulated
         conditional phase is equal per path; the divergence is rail COUNT (2 flags
         vs 1) and nothing else. h0 is never cqrt_x-bracketed and never freed on
         either side. Door: Track D's P4 -- the rolled half DECLINED on the ORACLE
         with `condition predates a non-diagonal gate` and compiles now (measured on
         3 of the 12, gate/probes/cellora.py).
digest   <FRESH>
rolled   <FRESH>
unrolled <FRESH>
```

## GROUP C-2 — 3 cells, bd `test_C_libtooling-drbq.12`, the `m_rz` x `_rz` corner

```
cell     m_rz_eq_rz
cell     m_rz_eq0_rz
cell     m_rz_gt_rz
class    -O1 DIAMOND FUSION WITH ANGLE PHIS. The matrix's rz PREFIX and SUFFIX are
         UNCONTROLLED cq_phi -- global phases, which Rule 3 DELETES on the rolled
         side (they are absent from the rolled stream entirely). On the FLAT side
         -O1 FUSES the two diamonds into one with two angle phis, so those same
         slots become an Rz-stem angle-select KICKBACK PAIR. The twin therefore
         emits a THIRD flag group and cqrt_x-bracketed prefix/suffix rotations the
         rolled side never emits: 11 lines vs 22, NOT the C-1 fold.
bd       test_C_libtooling-drbq.12
owner    ROLLED IS NOT DEFICIENT. Delta_rolled == Delta_unrolled == 2*PI per path,
         exactly: rolled h1:PI + h2:PI; twin (PI-0.125) + (+0.25) + (PI-0.125). The
         extra angles cancel PAIRWISE across adjacent flag groups -- each appears
         once unbracketed and once X-bracketed on the next group -- so the
         cancellation holds for ARBITRARY angles, verified with a NON-CANCELLING
         control (+0.125 / +0.3, trackD2/probes/rz_cells/nc_{rolled,unrolled}.c):
         relative Delta is 2*PI on BOTH sides there too. No FP rounding is involved;
         the compiler never sums the angles. All gates diagonal, all flags stripped
         and freed at |0>, h0 untouched.
         ⚠ READ WITH ITS LIMIT: Delta = 2*PI means the marked phase is e^(i2PI) = 1,
         so these three are PHASE-NEUTRAL -- they witness rail STRUCTURE, not a
         non-trivial marked phase (CLAUDE.md section 0's lesson in miniature). The
         NON-CANCELLING control is what carries the structural weight; do not cite
         these three as evidence that a non-trivial phase survives the roll.
         RETIREMENT TRIGGER (from trackD2/RZ_CELLS.md section 5): the blessing rests
         on cqrt_rz_i1 being DIAGONAL and on X.P(t).X == P(-t) up to a global phase.
         The day a phase arm emits anything NON-diagonal on a flag, or cqrt_x lands
         on h0 rather than an ancilla, Delta stops being additive and this must be
         re-derived FROM THE STREAMS, not re-read.
digest   <FRESH>
rolled   <FRESH>
unrolled <FRESH>
```

---

## (B) `q_armoncond` — re-pin, per the orchestrator's O1 delegation

Re-pin ONLY if the pass-2 signature is the one argued in `PASS2_PREP.md` (B):
`3fa9d45cd851c1b3`. If it is a THIRD value, Group 1's fix moved it again and the
argument must be re-derived before pinning.

Adjudication (the three parts O1 requires) is in `PASS2_PREP.md` (B):
track = **Group 1's P2** by string; verdict `TRACE-DIVERGENCE` UNCHANGED, only the
manifestation moved; per-trip argument = one `cqrt_free(h5)` crossing
`cq_template_sqrt_f64_unc(h3,h2)` and `cqrt_free(h1)`, all on DISJOINT rails, so they
commute; `h5` is proven-|0> by its own `_unc` on both sides.
