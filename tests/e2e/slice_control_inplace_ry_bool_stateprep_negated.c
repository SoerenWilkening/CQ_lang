/* slice_control_inplace_ry_bool_stateprep_negated.c — THE OWNER'S OWN PROGRAM.

   This is the SECOND REGION of `example/grover/grover_oracle_uncompute.c`
   (snapshot 2026-09-11) IN ISOLATION, verbatim:

       bool b0 = 0;  bool b1 = 0;
       b0 = cq_theta(b0, 0.5);
       if (b0 == 0) { b1 = cq_theta(b1, 0.5); }
       return cq_measure(b0) + cq_measure(b1);

   It is the shape bd `b6ap`'s multi-phi peel will hand to this code, and it
   needs BOTH halves of bd `test_C_libtooling-l4x4` sub-increment l4x4.b at once,
   plus one thing from the branch this one is based on:

     * THE RAIL GATE (l4x4.b). `clang -O1` gives `br i1 %b0` with no compare;
       before l4x4.b this declined `bare i1 register condition`.
     * ANTI-CONTROL (l4x4.b). `if (b0 == 0)` is an ORIENTATION-B diamond — the
       prep arm is the FALSE successor — and the compare form's answer, a
       `cqrt_x` bracket on the flag, is forbidden on a user register. The answer
       is Ry ADDITIVITY: prepare the rail, rotate it UNCONDITIONALLY by θ, and
       CANCEL that rotation under the register with −θ.
     * THE F2 NARROWING (Track C, bd `drbq.14`, the base of this branch). Both
       `b0` and the seed are `_Bool`, and an `i1` has only two values, so F2's
       edge-pinned-seed test collided on BOTH edges by construction until the
       2026-09-11 ruling excluded values on the CONDITION'S OWN BACKWARD WIRE.

   READ THE GOLDEN LINE BY LINE — this is the trace the owner asked for:
     1  cqrt_alloc_i1(0)  -> h0          — `b0`'s rail
     2  cqrt_ry_i1(h0, 0.5)              — `b0 = cq_theta(b0, 0.5)`
     3  cqrt_alloc_i1(0)  -> h1          — `b1`'s rail, PREPPED to the seed 0
     4  cqrt_ry_i1(h1, 0.5)              — the arm's Ry, fired UNCONDITIONALLY
     5  cqrt_ry_i1_controlled(h0, h1, -0.5)
                                         — cancelled when `b0 = 1`, which is
                                           exactly `if (b0 == 0)`
     6  cqrt_measure_i1(h0)
     7  cqrt_measure_i1(h1)

   NO `cqrt_x`. NO mint, NO strip, NO `cqrt_free`. Seven lines, all gates —
   which is the owner's standing instruction for this family: *"it should just be
   an application of gates."*

   ⚠ THE WHOLE FILE STILL DOES NOT COMPILE ON THIS BRANCH. `-O1` FUSES the
   owner's second and third `if`s into ONE diamond carrying TWO merge phis, which
   declines `control flow` (bd `b6ap`, on its own branch). The measured string
   for the file as it stands is recorded in
   `docs/prd/phase-04-swap-route-control/inc1-records/session-l4x4/probes/`. This
   slice is the REGION, not the file. */
int slice(void) {
    _Bool b0 = 0;
    _Bool b1 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0 == 0) {                 /* a NEGATED bare-rail condition            */
        b1 = cq_theta(b1, 0.5);    /* a controlled STATE PREP of a `_Bool`     */
    }
    return (int) cq_measure(b0) + (int) cq_measure(b1);
}
int main(void) { (void) slice(); return 0; }
