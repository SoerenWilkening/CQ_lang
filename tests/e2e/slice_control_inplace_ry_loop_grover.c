/* slice_control_inplace_ry_loop_grover.c — THE CUSTOMER (bd
   test_C_libtooling-drbq Increment 3, PRD §13). Canonical Grover written as a
   `for` loop, with an Rz ORACLE, a CONTROLLED Ry on an ancilla, and an **Ry**
   REFLECTION on the condition register.

   SOURCE INTENT — one Grover iteration per trip:
       O    if (q == 5) q = cq_phi(q, PI);      oracle: mark |5>          (Rz)
       cRy  if (q == 3) r = cq_theta(r, 0.9);   controlled Ry on an ANCILLA
       S†   q = cq_theta(q, -0.5);              un-prepare                (Ry)
       S    q = cq_theta(q, 0.5);               re-prepare                (Ry)

   THIS PROGRAM WAS **TWO** FENCES AWAY FROM COMPILING, AND ONLY ONE OF THEM WAS A
   LOOP FENCE. That is the fact this slice exists to record.

     * R7's loop half declined every in-loop control-in-place rotation arm
       (`control flow inside a loop body`) — Increment 3 part 3a lifts it.
     * `ArmClassify`'s final P1 fence read `(SawValueArm || !SawPhaseArm)`, which
       is PHASE-ARM-ONLY: a rotation arm sets `SawRotationArm` and never
       `SawPhaseArm`, so a condition wire carrying a PROVABLY-POST-REGION `cq_theta`
       (which the `S†`/`S` reflection is) declined `condition predates a
       non-diagonal gate` — WITH NO LOOP INVOLVED. Increment 3 part 3b adds the
       `SawRotationArm` disjunct.

   MEASURED, and it is the reason both halves shipped together: the HAND-UNROLLED
   TWIN of this program — which has no loop at all — DECLINES on the pre-Increment-3
   binary, at P1. An Increment 3 that lifted only R7 would have delivered the
   Rz-reflection and dtzb-offset loops and still declined the program it was scoped
   for, which is Rule 17's "a decline is not the development escape hatch".

   WHY THE STRIP IS STILL VALID with an Ry on the condition wire: `ProvenPostRegion`
   means the reflection is provably after the region's ENTIRE emitted stream, so at
   the moment it fires the flag is already stripped and freed. The trace below shows
   exactly that ordering — `cqrt_free(h3)` precedes `cqrt_ry_i32(h0, -0.5)`.

   THE TWIN IS THE WITNESS. This golden must be BYTE-IDENTICAL to
   slice_control_inplace_ry_loop_grover_unrolled.expected.log (ctest
   `e2e-inplace-ry-loop-grover-twin-identical`). Its blind spot is quoted with it:
   the oracle IS the flat lowering, so a defect the two paths SHARE is invisible
   here — the flat side's own witnesses are the Inc-1 lit family and
   tests/e2e/slice_control_inplace_ry.c.

   STRICT stage 2b. Two flags per activation, each minted, stripped and freed
   inside its own iteration; the two registers are left allocated (`q` because the
   user measures it, `r` because Increment 1's structural freeze keeps the whole-DAG
   spine off a rail carrying a controlled rotation — Rule 6's sanctioned fallback,
   and identical in the twin).

   K-INDEPENDENCE: the lowered IR must have the SAME line count at K=3 and at
   K=1000. A count that grows with K means the loop was unrolled and the
   increment's central claim is false. */

#define CQ_PI 3.14159265358979323846
#ifndef CQ_K
#define CQ_K 2
#endif

int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    for (int i = 0; i < CQ_K; ++i) {
        if (q == 5) {                    /* O   — Rz oracle                */
            q = cq_phi(q, CQ_PI);
        }
        if (q == 3) {                    /* cRy — controlled Ry on ancilla */
            r = cq_theta(r, 0.9);
        }
        q = cq_theta(q, -0.5);           /* S†  — Ry on the CONDITION wire */
        q = cq_theta(q, 0.5);            /* S                              */
    }

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
