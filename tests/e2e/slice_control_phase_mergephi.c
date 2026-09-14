/* slice_control_phase_mergephi.c — bd `3qps` (Track P). THE 3qps CUSTOMER, e2e.

   `slice_control_cascade_two_bools.c` with its `if (b1) a -= 3;` replaced by a
   register-free BRANCH PHASE, `if (b1) cq_phi(0.3);` — i.e. the owner's own
   cascade feeding the PHASE consumer instead of the value one.

   IT DECLINED ON THE FROZEN ORACLE (`59ac5b7`) with
       cq controlled lowering: branch phase on a bare i1 condition
   and the filing reason matters: the wire was CLEAN and the register was
   already a register to this compiler — the `int b1` twin
   (`slice_control_phase_mergephi_int.c`, 25 lines) lowered on that same binary
   with a COMPARE over the SAME merge phi. The blocker was purely the LEAF
   GRAMMAR at one gate: `isCondRailLeaf` admits a `cq_theta_i1` CALL and a
   `PHINode` was off-grammar. So this was a leaf-grammar OVER-DECLINE, NOT bd
   `drbq.7`'s wire fence — which still owns the CHAINED-arm shape and still
   declines it (`ir-pass/test/control_phase_kickback_reject_mergephi_chained_arm.ll`).

   READ THE GOLDEN LINE BY LINE:
      1-2   `b0`'s rail + its Ry.                  [`if (a >= 3)` folds: a == 5]
      3-5   `b1`'s rail, PREPPED to the seed 0, rotated UNCONDITIONALLY by 0.5,
            then CANCELLED under `b0` with -0.5 — Ry ADDITIVITY, which is how the
            compiler spells an anti-control. NEVER a `cqrt_x` on a user register.
      6     THE LINE THIS SLICE EXISTS FOR. `cqrt_rz_i1(h1, 0.3)` — the kickback,
            DIAGONAL, sitting directly on the user's prepped register. NOTHING is
            minted, stripped or freed for it: the register IS the flag (Rule 7).
      7-17  `if (b0 == 1) a -= 3` — the peeled `a`-mux as the rail-root CNOT-copy
            merge. MEASURED byte-identical to
            `slice_control_cascade_two_bools.expected.log` lines 6-16, which is
            the cross-check that this increment moved NOTHING on the value path.
     18-20  the three measurements.

   THE INVARIANTS, readable straight off the golden:
     * `h0` and `h1` are the USER'S REGISTERS. `h1` appears at arg 0 of exactly
       one `cqrt_rz_i1` (a DIAGONAL gate) and nowhere else; `h0` appears only as
       a CONTROL of `cqrt_ry_i1_controlled` and at arg 0 of the two `cqrt_cnot`.
     * BOTH `cqrt_x` are on the ancilla `h2`; none on a user register.
     * ONE `cqrt_free`, of that same ancilla, returned to `x ^ x = 0` on every
       branch. Neither user register is freed (`Ry(t)|0> != |0>`, Rule 6), and
       STRICT stage 2b agrees: `6 rail mint(s) of which 5 left allocated,
       1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven`.

   ⚠ THE GOLDEN IS ALSO A CROSS-CHECK, not just a record. The whole stream is
   BYTE-IDENTICAL to what the FROZEN ORACLE prints for the hand-IR twin
   `trackP/probes/p17.ll` (the same module after the prep's M-beta) except for
   ONE line: line 5 is `cqrt_ry_i1_controlled(h0, h1, -0.5)` here and the
   uncontrolled `cqrt_ry_i1(h1, -0.5)` there, because the hand-IR twin has no
   prep region left to control it. Everything the widening contributes — line 6
   included — the ORACLE already emits. The widening adds an ACCEPT, not a
   STREAM. */
int slice(void) {
    int a = 5;
    _Bool b0 = 0;
    _Bool b1 = 0;

    if (a >= 3){
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    if (a >= 3){
        b1 = cq_theta(b1, 0.5);
    }
    if (b1) cq_phi(0.3);

    return (int) cq_measure(b0) + (int) cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
