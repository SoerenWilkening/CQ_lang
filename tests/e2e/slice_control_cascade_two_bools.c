/* slice_control_cascade_two_bools.c — THE OWNER'S OWN FILE.

   `example/grover/grover_oracle_uncompute.c` (snapshot 2026-09-13), the live
   code lines verbatim — two `_Bool`s, no `int` workaround, no new `cq_*`
   function. The only edit is the harness one: `main` -> `slice`.

   IT DECLINED ON 2026-09-13 MORNING and the string was
       cq controlled lowering: control flow under quantum control
   anchored at `%7 = select i1 %5, i32 %6, i32 %cq.peel.mux`. The blocker was a
   LEAF-GRAMMAR gap at ONE gate: `if (b1) a -= 3;` leaves `-O1` a `select` whose
   condition is the prep diamond's MERGE phi, and `collectCondTree` admitted a
   `cq_theta_i1` CALL as a rail leaf but not a phi (bd `boi6` D-B / Track M).

   ⚠ THE ASYMMETRY THAT MADE IT ABSURD, and it is the clearest statement of the
   defect: `if (b1) a -= 1;` COMPILED on the same binary while `if (b1) a -= 3;`
   did not. Not semantics — InstCombine. A +-1 delta folds to
   `add(a, sext b1)`, i.e. straight-line tainted ARITHMETIC on the merge phi with
   no control region at all, so the phi was ALREADY consumed as a quantum
   register; every other delta leaves a `select`, and only the `select` consumer
   was refused.

   READ THE GOLDEN LINE BY LINE — this is the trace the owner asked for:
      1-2   `b0`'s rail + its Ry.                  [`if (a >= 3)` folds: a == 5]
      3-5   `b1`'s rail, PREPPED to the seed 0, rotated UNCONDITIONALLY by 0.5,
            then CANCELLED under `b0` with -0.5 — Ry ADDITIVITY, which is how the
            compiler spells an anti-control. `a` is 2 or 5 after the first
            region, so `a >= 3` IS `b0 == 0`. NEVER a `cqrt_x` on a user
            register.
      6-16  `if (b0 == 1) a -= 3` — the peeled `a`-mux, as the rail-root
            CNOT-copy merge: copy `b0`'s basis label into a |0> ancilla, two
            X-bracketed controlled copies into a fresh |0> out rail, un-copy,
            free at a proven |0>.
     17-26  `if (b1) a -= 3` — THE LINE THIS SLICE EXISTS FOR. The arm's chain is
            HOISTED (`cq_template_add_i32_hl(h3, -3)`), then the same merge with
            the PREPPED REGISTER `h1` as the control.
     27-29  the three measurements.

   THE THREE INVARIANTS, readable straight off the golden:
     * `h0` and `h1` are the USER'S REGISTERS and each appears ONLY at arg 0 of a
       `cqrt_cnot` or as the CONTROL of `cqrt_ry_i1_controlled` — read-only.
     * ALL FOUR `cqrt_x` are on the ancillas `h2`/`h7`; none on a user register.
     * the two `cqrt_free` are those same ancillas, each returned to `x ^ x = 0`
       on every branch. Neither user register is freed (`Ry(t)|0> != |0>`,
       Rule 6), and the hoisted chain rail `h6` is LEFT ALLOCATED — the Rule-6
       "value arm's chain-final rail" case. STRICT stage 2b agrees:
       `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s):
        2 verified, 0 violation(s), 0 unproven`.

   ⚠ THE GOLDEN IS ALSO A CROSS-CHECK, not just a record. Lines 1-16 are
   `slice_control_cascade_two_bools_base.c`'s golden BYTE FOR BYTE (that slice is
   this program with line 99 removed), and lines 17-26 are the select half the
   FROZEN ORACLE already prints for the hand-IR twin
   `ir-pass/test/control_swap_accept_select_rail_after_prep_negated.ll`. The
   widening adds an ACCEPT, not a STREAM. */
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
    if (b1) a -= 3;

    return (int) cq_measure(b0) + (int) cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
