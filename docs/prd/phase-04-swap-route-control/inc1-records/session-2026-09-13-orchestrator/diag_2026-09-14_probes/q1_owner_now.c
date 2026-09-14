/* grover_oracle_uncompute.c — Grover, step 2: S, O, S-dagger.
 *
 *     S      state prep   : Ry(0.5)
 *     O      oracle       : phase-flip the marked set
 *     S†     un-prepare   : Ry(-0.5)
 *     M      measure
 *
 * Half a Grover iteration.  For the reflection about |0> as well -- and the
 * closing re-preparation that makes it a COMPLETE iteration -- see
 * grover_iteration.c.
 *
 * THIS FILE USED TO DECLINE, AND IT IS WORTH KNOWING WHY IT NO LONGER DOES.
 * The `cq_theta(a, -0.5)` below sits on the very wire the oracle's condition
 * read, and the stale-condition guard was schedule-independent: any theta
 * anywhere on that wire declined the region, even one that runs strictly after
 * the flag was minted, used, stripped and freed.  Measured at HEAD b4e329b this
 * program exited 1 with
 *     cq controlled lowering: condition predates a non-diagonal gate
 *                             under quantum control
 * and it runs since bd test_C_libtooling-lom0 Increment 4 made that walk
 * position-aware for a flat phase region.  (README.md's "runs" row for this file
 * predated the file's contents and was wrong for a while -- bd
 * test_C_libtooling-upfv.  Every row there is re-measured now.)
 *
 * WATCH WHAT clang -O1 DOES TO THE CONDITION, because the trace will not match
 * what you typed (Rule 9).  `a + 3 <= 3` is canonicalized to `a < 1`, so the
 * emitted flag is `cq_template_icmp_slt_i32_hl(h0, 1)` and there is no `add` in
 * the program at all.  That also means this oracle's condition is DIRECT -- an
 * `icmp` on the register itself -- which is the case where the compare flag is
 * the region's only record of the wire and the `_unc` strip discharges it.
 *
 * A DERIVED CONDITION USED TO DECLINE HERE, AND SINCE 2026-08-29 IT DOES NOT.
 * Write a condition -O1 cannot fold into a single compare (`sqrt(a+3.0) <= 5.0`)
 * and this same program used to exit 1 with
 *     cq rotation lowering: non-diagonal gate over a live derived record
 * because the sitofp/fadd/sqrt rails the compare built were still allocated and
 * entangled with the wire when the S-dagger Ry fired (bd
 * test_C_libtooling-6uqc).  M-B Increment 6 (bd test_C_libtooling-160a) closed
 * it: the swap-route emitter now RECORDS its flag strip, the interior uncompute
 * partition admits a recorded strip as a READ of the rails it names, anchors the
 * chain's reversal immediately after it, and admits the region's `cqrt_cswap`
 * route as a matched label-restoring pair.  The chain is uncomputed LIFO and
 * freed between the strip and the flag free, so the S-dagger Ry fires with only
 * the register allocated.  Measured, and shipped as
 * tests/e2e/slice_uncompute_interior_region_derived_cond.c and, for the whole
 * iteration, grover_derived_oracle.c beside this file.
 *
 * WHAT STILL LEAKS, so the mechanism is not universal: a chain whose wire is
 * written non-diagonally (a chained theta, a measurement) strictly between the
 * chain and the discharge point, and any condition chain whose strip belongs to
 * an emitter that does not record one -- the 4.4 select, the method-B value arm,
 * the 4.3 nest, the 4.5 switch, the 6.5 classical-call arm.
 *
 * AND SINCE 2026-08-29 THOSE NO LONGER DECLINE EITHER -- THEY WARN (owner
 * ruling, bd test_C_libtooling-lyyf; M-A Increment 7b).  When a record IS left
 * standing at a chained rotation the compiler now prints
 *     warning: ... cq rotation lowering: non-diagonal gate over a live derived
 *                  record
 * on stderr, exits ZERO, and emits the circuit -- with the record LEFT
 * ALLOCATED, never freed (Rule 6 is untouched).  The reasoning is the owner's:
 * "we can always apply any unitary operation we want.  Again, it is the user's
 * fault to have produced a badly functioning code" -- a dephased rotation is a
 * realizable unitary, just not the one the author probably meant, so the
 * compiler says so rather than refusing.  Read every "declines" above as
 * "warns and lowers"; the ANALYSIS behind the message did not move one clause.
 * Guards for a WRONG VALUE (declineStaleRecordOps, the condition-wire fences)
 * and for a DIRTY FREE (FreePoint, Uncomputation) are NOT covered by that
 * ruling and are still loud.
 *
 * THE OFFSET TRICK NOW COMPOSES WITH A DERIVED ORACLE (bd
 * test_C_libtooling-x67f, M-C Increment 7a).  Writing the preparation as
 * `a = cq_theta(a, 0.5); a += off;` and the un-preparation as `a -= off;
 * a = cq_theta(a, -0.5);` around a DERIVED oracle used to leave the `a -= off`
 * out of place -- `lowerOps` runs before `uncompute`, so the chain's planned
 * discharge was invisible to the in-place fence -- which minted a fresh rail and
 * left the original register a dead record at the S-dagger.  A late
 * reassignment round now re-asks that fence with the discharge plan in hand.
 * Shipped as tests/e2e/slice_control_grover_derived_oracle_offset.c.
 *
 * Build + run:
 *     ./tools/show_pipeline.sh example/grover/grover_oracle_uncompute.c
 */
#include "CQ.h"
#include <math.h>

int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    bool b2 = 0;
    
    if (a >= 3){
        b0 = cq_theta(b0, 0.5);
    }
    if (b0) a -= 3;
    
    if (a >= 3){
        b1 = cq_theta(b1, 0.5);
    }
    if (b1) a -= 3;

    if (a >= 3){
        b2 = cq_theta(b2, 0.5);
    }


//    if (b1 == 0) a -= 3;
//
//
//    for (int i = 0; i < 2; ++i) {
//        /* --- O: mark the low end ---------------------------------------------- */
//        if (pow(sqrt(a) + 3.1, 0.5) - .2 <= M_PI * 4.1) {
//            a = cq_phi(a, M_PI);
//        }
//
//        /* --- S-dagger: the exact inverse of S ---------------------------------- */
//        a = cq_theta(a, -0.5);
//
//        if (a == 0) {
//            a = cq_phi(a, M_PI);
//        }
//
//        a = cq_theta(a, 0.5);
//    }
    
    return cq_measure(b0) + cq_measure(b1)  + cq_measure(b2) + cq_measure(a);
}
