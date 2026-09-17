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

   THIS (UNROLLED) HALF STILL COMPILES THE HAZARD AT EXIT 0, AND NOTHING REFUSES
   IT. declineUndischargedMarkedBodyRails is LOOP-SCOPED by construction — it
   verifies a promise conjunct (1) makes about a MARKED LOOP BODY — and this
   module has no loop at all. So the fix that refuses the rolled twin
   structurally CANNOT reach this one. That is a NEW P1, filed in
   trackT2/BD_TEXT.md ("two shipped goldens pinned a Rule-8 wrong unitary under a
   green twin-identical gate"), and it is NOT something this increment closed. It
   is kept unregistered so the program survives for that bead's red-green pair.
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
/* slice_control_inplace_ry_loop_leak_unrolled.c — the hand-unrolled twin of
 * slice_control_inplace_ry_loop_leak.c (bd test_C_libtooling-drbq Increment 3,
 * round-1 lens L3 Q1). Same text, dedented and written out twice.
 *
 * Its job is to show that the O(K) freeze leak the rolled slice measures is the
 * FREEZE's cost and not the ROLL's: this flat form strands the same 2 template
 * rails per repetition, for the same reason, and its trace is BYTE-IDENTICAL
 * (ctest `e2e-inplace-ry-loop-leak-twin-identical`).
 *
 * Unlike the rolled side this program compiles on the PRE-Increment-3 binary
 * too — it is the Increment-1 flat control-in-place lowering, which is the stated
 * oracle for every slice in this family.
 */
#include <stdio.h>

int slice(void) {
    int q = 0; int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    { int s = r * 7; printf("%d\n", s); }
    if (q == 5) { r = cq_theta(r, 0.9); }
    cq_phi(0.1);
    q = cq_theta(q, 0.05);   /* OQ-3: the loop-VARIANT maker */
    { int s = r * 7; printf("%d\n", s); }
    if (q == 5) { r = cq_theta(r, 0.9); }
    cq_phi(0.1);
    q = cq_theta(q, 0.05);   /* OQ-3: the loop-VARIANT maker */
    return cq_measure(q) + cq_measure(r);
}

int main(void) { (void)slice(); return 0; }
