/* ══════════════════════════════════════════════════════════════════════════
   UNREGISTERED AND CONVERTED 2026-09-18 — bd `test_C_libtooling-6n1s` F-1.
   THE HEADER BELOW IS KEPT VERBATIM AS HISTORY; ITS CENTRAL CLAIM IS FALSE.

   This slice used to assert "IT IS RULE-6 CORRECT". CLAUDE.md §5's Q-R1-1
   correction ruled that exact sentence FALSE for three sibling fixtures, and it
   is false here for the same reason: **Rule 6 governs whether a dirty rail may
   be FREED. It says nothing about whether leaving one ENTANGLED is semantically
   free, and Rule 8 says it is not.**

   THE HAZARD, read off the (now deleted) golden — identical in the rolled and
   the unrolled half:

       cq_template_mul_i32_hl(h2, 7) -> h3     <- a COHERENT copy of h2's label
       cqrt_tape_write_i32(t0, h3) -> h4       <- a COPY into the output tape:
                                                  h3 is NOT collapsed and stays
                                                  entangled with h2
       cqrt_ry_i32_controlled(h5, h2, 0.9)     <- NON-DIAGONAL, on h2
       ... and again, h6 / h7 ...
       cqrt_measure_i32(h2)                    <- h2 IS the observable

   h3/h6 are never _unc'd and never freed. A which-path record of h2 therefore
   stands at a non-diagonal gate on h2, and h2 is measured — Rule 8 verbatim.
   NOTE: only the tape-write RESULT (h4, h7) is an OutputRails member; its
   OPERAND h3 is an ordinary interior template rail, so "it is the program's own
   output" does NOT excuse it.

   THE TWIN-IDENTICAL GATE COULD NOT SEE THIS, and that is the instrument
   lesson. e2e-inplace-ry-loop-leak-twin-identical compared the two goldens and
   PASSED — because BOTH halves are wrong in the same way. CLAUDE.md L10 has the
   general form: "a cell whose two halves agreed because BOTH were wrong is
   precisely what ACCEPT-IDENTICAL cannot see; only a fence can."

   BOTH goldens are DELETED (not regenerated) and all three ctest entries are
   unregistered — the 2026-09-14 stale-reader precedent. The .c files are KEPT,
   because a renamed-or-deleted fixture can be resurrected by a merge (L8, bd
   gahu).

   L8 RETIREMENT TRIGGER: the day the which-path leak of this family gains a
   real placement, both files become ACCEPTs again and the twin gate can be
   restored — re-derive both streams then against the hand-unrolled twin's
   MULTISET (owner ruling S3, 2026-09-17: byte identity is the INSTRUMENT, not
   the claim), and do NOT restore the deleted goldens, which pin the leaking
   stream.

   THIS (ROLLED) HALF NOW DECLINES, and the decline is pinned:
   `cq loop lowering: rolled body leaks a rail entangled with a rotated register`,
   emitted by declineUndischargedMarkedBodyRails — conjunct (1) records the
   marked body's promise and the postcondition checks it after uncompute. The
   verbatim stage-1 module is
   ir-pass/test/loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll,
   validated NON-VACUOUS by binary mutation (it does not match on the ORACLE,
   where opt exits 0).
   ══════════════════════════════════════════════════════════════════════════ */

/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-3 / prep-b2): one statement ADDED —
   `q = cq_theta(q, 0.05);` immediately after each `cq_phi(0.1);`. The golden
   below is therefore a NEW PROGRAM's trace, not an audit substitution of the
   old one, and it is recorded as such in
   docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

   WHY (MEASURED, prep-b PROBE 1 + prep-b2 step 2). On the retired surface the
   trailing statement was `q = cq_phi(q, 0.1);` — an in-place gate on the
   CONDITION register, which is what made `q` loop-VARIANT. Register-free,
   `cq_phi(0.1)` reads nothing, `q` becomes loop-INVARIANT, `clang -O1` LICM-hoists
   `icmp eq i32 %q, 5` into the entry block, and `condWireDisposition`'s P4
   precondition declines the whole slice with
   `cq controlled lowering: condition predates a non-diagonal gate under quantum control`
   — on the pre-3qlq ORACLE and on the Increment-1 SUBJECT alike (both measured;
   the decline is the drbq.12 / CLAUDE.md "row W" over-decline and is not
   anything Increment 1 introduced). `cq_theta` is the only primitive that both
   READS the register and relabels its wire, so it is the replacement
   variant-maker, and it is exactly the shape the drbq Inc-3 Grover customer has.
   The uncontrolled `cq_phi(0.1)` is KEPT where it stood: under D2 it is a global
   phase and the pass deletes it, so it documents the original intent and costs
   the trace nothing (audit substitution class (c)). */
/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, 0.1)` -> `cq_phi(0.1)` (the Ry arms are untouched -- Rz stem only).
   FLAG (the load-bearing one for this family): that Rz was NOT decoration. Its job
   was to keep the CONDITION register q loop-VARIANT (drbq PRD S13.1). A register-free
   cq_phi returns nothing, so q is the same SSA value on every trip, `-O1` LICM hoists
   `icmp eq q, 5` out of the loop, and condWireDisposition's P4 precondition declines
   `condition predates a non-diagonal gate` (CLAUDE.md row W / drbq.12). MEASURE this
   before assuming; if it holds, the shape needs a DIFFERENT variant-maker (an Ry,
   `q = cq_theta(q, 0.1)`) and that is a semantic change, not a migration.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_inplace_ry_loop_leak.c — bd test_C_libtooling-drbq Increment 3,
 * round-1 lens L3 Q1. THE O(K) FREEZE LEAK, MEASURED.
 *
 * PRD §13.5 says the Increment-1 structural freeze (a rail carrying a controlled
 * rotation is `NotClosed`, never reverse-played, never freed) costs "K rails at
 * run time" when the body DERIVES anything from the frozen register — one leaked
 * template rail per activation per derivation, linear in the trip count. Until
 * this slice that claim was ANALYTIC: no shipped slice read the rotated register
 * inside the body, because the obvious spellings are refused (a read AFTER the
 * region is `cq opcode lowering: operand predates a non-diagonal gate`; a read in
 * a SECOND loop is a classical-condition mux).
 *
 * The one spelling that works is to read the register BEFORE the region in the
 * same body: the read then precedes that activation's own relabelling gate, and
 * the back edge does not stale it because the loop-carried `r` phi crosses a real
 * rail gate every trip (the 8h7d.5 F-2 refresh rule).
 *
 * MEASURED (K=2 here; L3 also ran K=3): per activation the body emits
 *     cq_template_mul_i32_hl(hR, 7) -> hS      <- entangled with the FROZEN r
 *     cqrt_tape_write_i32(t0, hS)  -> hT       <- second rail
 * and NOTHING EVER FREES EITHER. 2 leaked template rails per activation — 4 at
 * K=2, 6 at K=3 — while the only `cqrt_free` per trip is the region's own flag.
 *
 * IT IS RULE-6 CORRECT AND IT IS NOT A REGRESSION. Every leaked rail is LEFT
 * ALLOCATED; none is freed dirty. Strict stage 2b is BLIND to it by construction
 * (its census counts `cqrt_alloc` mints and these rails are TEMPLATE-minted —
 * read that checker's header), which is exactly why the claim needs a golden and
 * a twin rather than a gate.
 *
 * AND THE TWIN LEAKS THE SAME RAILS FOR THE SAME REASON, which is the point of
 * the pair: `..._leak_unrolled.c` is byte-identical (ctest
 * `e2e-inplace-ry-loop-leak-twin-identical`). The cost is the FREEZE's, not the
 * ROLL's — a reader who sees 2K stranded rails must not conclude the loop
 * lowering invented them.
 *
 * ORACLE: the rolled form DECLINES on the pre-Increment-3 binary (`control flow
 * inside a loop body under quantum control`); the flat twin lowers identically on
 * both. So this slice is Increment 3's own new population.
 */
#include <stdio.h>

int slice(void) {
    int q = 0; int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    for (int i = 0; i < 2; ++i) {
        int s = r * 7;
        printf("%d\n", s);
        if (q == 5) { r = cq_theta(r, 0.9); }
        cq_phi(0.1);
        q = cq_theta(q, 0.05);   /* OQ-3: the loop-VARIANT maker */
    }
    return cq_measure(q) + cq_measure(r);
}

int main(void) { (void)slice(); return 0; }
