/* 3qlq Inc 1: migrated to register-free cq_phi -- every oracle / reflection arm's `q = cq_phi(q, PI)` -> `cq_phi(PI)`.

   FINDING (PRD S1, measured 2026-09-05 at HEAD 52d7764): the PRE-3qlq golden of
   this slice encoded a CONTROLLED TENSORED Rz, which is the IDENTITY on q --
   `cqrt_rz_<W>` is "Rz on each qubit", so the marked phase is (-1)^popcount(target)
   (= +1 for |5>) and a per-qubit diagonal gate FIXES |0..0>, so the |0> reflection
   can never put -1 there. Any claim in the prose below that the oracle marks |5>,
   or that the reflection reflects about |0>, was TRUE OF THE SOURCE and FALSE OF
   THE EMITTED CIRCUIT. It becomes true only from 3qlq Inc 1 on, where the phase is
   a BRANCH phase by kickback (rz_i1 on the minted flag), not a register Rz. The
   older prose was revised on 2026-10-05 (bd 7pxe); remaining register-Rz wording is history.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_grover_derived_oracle.c — ONE COMPLETE GROVER ITERATION WITH A
   NON-TRIVIAL ORACLE. The customer M-B Increment 6 was built for.

   SOURCE INTENT — the textbook iteration, every step written out:
       S    cq_theta(&q, 0.5);                     state preparation
       O    if (((q * 5) >> 2) == 5) cq_phi(PI);    the DERIVED oracle
       S-   cq_theta(&q, -0.5);                    un-prepare
       R0   if (q == 0) cq_phi(PI);            reflect about |0>
       S    cq_theta(&q, 0.5);                     re-prepare
       M    measure q

   WHY THIS SLICE EXISTS BESIDE slice_control_grover_2iter.c. That one's oracle
   is `if (q == 5)` — a DIRECT compare on the register, whose only record is the
   flag the emitter already strips. This one's oracle is a COMPUTATION: `clang
   -O1` rewrites `(q*5)>>2` as `q + (q>>2)` (exact — 4q's low bits are zero), so
   the condition is reached through TWO template rails, an `ashr` and a QQ `add`,
   before the flag is even minted. Until Increment 6 those rails were never
   uncomputed, so this program declined at the S-dagger with "cq rotation
   lowering: non-diagonal gate over a live derived record". An oracle that can
   only test the register against a constant is not an oracle; this is the slice
   that says CQ can mark a computed predicate.

   WHICH STATE IT MARKS, AND WHY THAT MATTERS (bd test_C_libtooling-160a Rule-13
   round, finding F2). `(q*5)>>2 == 5` holds exactly when 20 <= 5q <= 23, i.e.
   for q == 4 and no other integer — so the oracle really does phase-mark one
   basis state a C program may legally reach. The predicate this slice shipped
   with, `(q*37)>>3 == 5`, needs 40 <= 37q <= 47 and has NO integer solution
   without `mul nsw` overflow (UB in the source): the emitted circuit was
   shape-identical, so nothing about the lowering turned on it, but a header
   that sells the slice as "CQ can mark a computed predicate" over a predicate
   that marks nothing is the kind of claim this project does not make. A reader
   who checks must find the claim true.

   R0 IS DELIBERATELY DIRECT. The reflection about |0> really is `q == 0`, and
   keeping it direct makes the trace show BOTH condition shapes in one program:
   the oracle's chain is uncomputed after its strip, the reflection's flag is
   simply stripped and freed.

   WHAT THE TRACE WITNESSES. For the oracle region: ashr, add, flag mint, the
   kickback cqrt_rz_i1 on the flag, flag STRIP, then add-unc + free, ashr-unc +
   free, then the flag free — and only then the S-dagger cqrt_ry_i32. For the R0
   region: flag mint, cqrt_rz_i1 on the flag, strip, free — then the final
   cqrt_ry_i32.

   RAIL LIVENESS AT EVERY NON-DIAGONAL GATE (the reading the golden cannot do for
   itself): cqrt_alloc_i32 appears ONCE — the register h0; the oracle's records
   and each region's flag are template-minted and freed inside their own region.
   At each of the three cqrt_ry_i32 gates the only allocated rail is h0. Strict
   stage 2b (no --allow-unproven) confirms it from the rail side.

   IT IS NOT, BY ITSELF, CORRECTNESS EVIDENCE (bd nepx): read it with the
   liveness reading, the strict free-pairing, and the adversarial round. */

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;

    cq_theta(&q, 0.5);                          /* S  */
    if (((q * 5) >> 2) == 5) {                  /* O — the derived oracle; marks q == 4 */
        cq_phi(CQ_PI);
    }
    cq_theta(&q, -0.5);                         /* S- */
    if (q == 0) {                               /* R0 */
        cq_phi(CQ_PI);
    }
    cq_theta(&q, 0.5);                          /* S  */
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
