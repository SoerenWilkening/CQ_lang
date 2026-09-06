/* 3qlq Inc 1: migrated to register-free cq_phi -- every oracle / reflection arm's `q = cq_phi(q, PI)` -> `cq_phi(PI)`.

   FINDING (PRD S1, measured 2026-09-05 at HEAD 52d7764): the PRE-3qlq golden of
   this slice encoded a CONTROLLED TENSORED Rz, which is the IDENTITY on q --
   `cqrt_rz_<W>` is "Rz on each qubit", so the marked phase is (-1)^popcount(target)
   (= +1 for |5>) and a per-qubit diagonal gate FIXES |0..0>, so the |0> reflection
   can never put -1 there. Any claim in the prose below that the oracle marks |5>,
   or that the reflection reflects about |0>, was TRUE OF THE SOURCE and FALSE OF
   THE EMITTED CIRCUIT. It becomes true only from 3qlq Inc 1 on, where the phase is
   a BRANCH phase by kickback (rz_i1 on the minted flag), not a register Rz. The
   older prose is left verbatim rather than silently corrected; read it with this.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_grover_derived_oracle_2iter.c — TWO COMPLETE GROVER ITERATIONS
   WITH A NON-TRIVIAL ORACLE. The slice that needs BOTH halves of M-B Increment
   6 at once, and the one that would not lower with either half alone.

   SOURCE INTENT — the body of slice_control_grover_derived_oracle.c, twice,
   plus the final re-prep:
       S    q = cq_theta(q, 0.5);
       O    if (((q * 5) >> 2) == 5) cq_phi(PI);     the DERIVED oracle (marks q == 4)
       S-   q = cq_theta(q, -0.5);
       R0   if (q == 0) cq_phi(PI);
       S    q = cq_theta(q, 0.5);
       O    if (((q * 5) >> 2) == 5) cq_phi(PI);
       S-   q = cq_theta(q, -0.5);
       R0   if (q == 0) cq_phi(PI);
       S    q = cq_theta(q, 0.5);
       M    measure q

   WHY IT NEEDS THE PER-COMPONENT ANCHOR (Increment 6a) AND NOT ONLY CLAUSE (d2).
   The two oracles compute the SAME expression on DIFFERENT states, so they mint
   two condition chains with no producer edge between them: two components.
   Increment 5 computed ONE insertion point per FUNCTION — the nearest common
   post-dominator of every consumer of every interior rail — which for this
   program lands after iteration 2's flag strip. Iteration 1's chain would then
   be uncomputed there, with iteration 1's S-dagger cqrt_ry_i32 on the shared
   register STRICTLY INSIDE its clause-(d) interval. That is exactly the
   placement the owner's 2026-08-27 ruling forbids (an _unc after a non-diagonal
   wire gate reads a post-Ry basis), so clause (d) refused, the WHOLE function
   leaked, and the program declined at the M-A guard. Per component each chain
   anchors at its OWN region's strip, and both discharge.

   WHAT THE TRACE WITNESSES: FOUR regions and FIVE cqrt_ry_i32 gates, and before
   every one of those five gates every ancilla minted since the previous one has
   been uncomputed and freed. The two oracle regions each show
   ashr / add / mint / route / Rz / route / rail-free / STRIP / add-unc+free /
   ashr-unc+free / flag-free; the two R0 regions each show mint / route / Rz /
   route / rail-free / strip / flag-free.

   THE PREDICATE IS SATISFIABLE, and that is deliberate (bd
   test_C_libtooling-160a Rule-13 round, finding F2): `(q*5)>>2 == 5` holds
   exactly for q == 4. The predicate both Grover slices shipped with,
   `(q*37)>>3 == 5`, has no integer solution without `mul nsw` overflow — the
   circuit was shape-identical, but an oracle that marks nothing is not an
   oracle, and the header said it was one. See the sibling slice's header for
   the full note.

   RAIL LIVENESS AT EVERY NON-DIAGONAL GATE (the reading the golden cannot do
   for itself): cqrt_alloc_i32 appears FIVE times — the register h0 plus one work
   rail per region — and each work rail is freed inside its own region. At each
   of the five cqrt_ry_i32 gates the only allocated rail in the program is h0.
   Strict stage 2b (no --allow-unproven) confirms it from the rail side: every
   free verified, the single rail left allocated is the measured register.

   IT IS NOT, BY ITSELF, CORRECTNESS EVIDENCE (bd nepx): read it with the
   liveness reading, the strict free-pairing, and the adversarial round. */

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);                       /* S  — iteration 1 */
    if (((q * 5) >> 2) == 5) {                  /* O  — marks q == 4 */
        cq_phi(CQ_PI);
    }
    q = cq_theta(q, -0.5);                      /* S- */
    if (q == 0) {                               /* R0 */
        cq_phi(CQ_PI);
    }

    q = cq_theta(q, 0.5);                       /* S  — iteration 2 */
    if (((q * 5) >> 2) == 5) {                  /* O  — marks q == 4 */
        cq_phi(CQ_PI);
    }
    q = cq_theta(q, -0.5);                      /* S- */
    if (q == 0) {                               /* R0 */
        cq_phi(CQ_PI);
    }

    q = cq_theta(q, 0.5);                       /* final re-prep */
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
