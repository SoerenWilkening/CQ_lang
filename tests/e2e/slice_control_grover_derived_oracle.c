/* slice_control_grover_derived_oracle.c — ONE COMPLETE GROVER ITERATION WITH A
   NON-TRIVIAL ORACLE. The customer M-B Increment 6 was built for.

   SOURCE INTENT — the textbook iteration, every step written out:
       S    q = cq_theta(q, 0.5);                     state preparation
       O    if (((q * 37) >> 3) == 5) q = cq_phi(q, PI);   the DERIVED oracle
       S-   q = cq_theta(q, -0.5);                    un-prepare
       R0   if (q == 0) q = cq_phi(q, PI);            reflect about |0>
       S    q = cq_theta(q, 0.5);                     re-prepare
       M    measure q

   WHY THIS SLICE EXISTS BESIDE slice_control_grover_2iter.c. That one's oracle
   is `if (q == 5)` — a DIRECT compare on the register, whose only record is the
   flag the emitter already strips. This one's oracle is a COMPUTATION: `clang
   -O1` canonicalizes `(q*37)>>3 == 5` into `(q*37) & -8 == 40`, so the condition
   is reached through TWO template rails before the flag is even minted. Until
   Increment 6 those rails were never uncomputed, so this program declined at the
   S-dagger with "cq rotation lowering: non-diagonal gate over a live derived
   record". An oracle that can only test the register against a constant is not
   an oracle; this is the slice that says CQ can mark a computed predicate.

   R0 IS DELIBERATELY DIRECT. The reflection about |0> really is `q == 0`, and
   keeping it direct makes the trace show BOTH condition shapes in one program:
   the oracle's chain is uncomputed after its strip, the reflection's flag is
   simply stripped and freed.

   WHAT THE TRACE WITNESSES. For the oracle region: mul, and, flag mint, route,
   Rz, route back, work-rail free, flag STRIP, then and-unc + free, mul-unc +
   free, then the flag free — and only then the S-dagger cqrt_ry_i32. For the R0
   region: flag mint, route, Rz, route back, free, strip, free — then the final
   cqrt_ry_i32.

   RAIL LIVENESS AT EVERY NON-DIAGONAL GATE (the reading the golden cannot do for
   itself): cqrt_alloc_i32 appears THREE times — the register h0 and one work
   rail per region — and each work rail is freed inside its own region. At each
   of the three cqrt_ry_i32 gates the only allocated rail is h0. Strict stage 2b
   (no --allow-unproven) confirms it from the rail side.

   IT IS NOT, BY ITSELF, CORRECTNESS EVIDENCE (bd nepx): read it with the
   liveness reading, the strict free-pairing, and the adversarial round. */

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);                       /* S  */
    if (((q * 37) >> 3) == 5) {                 /* O  — the derived oracle */
        q = cq_phi(q, CQ_PI);
    }
    q = cq_theta(q, -0.5);                      /* S- */
    if (q == 0) {                               /* R0 */
        q = cq_phi(q, CQ_PI);
    }
    q = cq_theta(q, 0.5);                       /* S  */
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
