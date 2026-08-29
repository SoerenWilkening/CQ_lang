/* slice_uncompute_interior_region_derived_cond.c — bd test_C_libtooling-6uqc's
   P0, end to end, WITH the S-dagger that used to make it decline. The e2e
   customer for M-B Increment 6 (clause (d2), the emitter-recorded flag-strip
   anchor).

   SOURCE INTENT:
       a = cq_theta(a, 0.5);
       if (sqrt((double)a + 3.0) <= 5.0) a = cq_phi(a, PI);   the oracle
       a = cq_theta(a, -0.5);                                 the S-dagger
       return cq_measure(a);

   WHAT MADE IT THE BLOCKER. The condition is DERIVED, so the compiler mints
   three template rails to compute it — sitofp, fadd, sqrt — and the swap-route
   emitter strips only the FLAG. At HEAD c36934a all three stayed allocated and
   entangled with the register forever; with the S-dagger present the program
   DECLINED outright ("cq rotation lowering: non-diagonal gate over a live
   derived record"), because a non-diagonal gate over three live basis records of
   the wire is a dephased circuit, not a Grover step. That single diagnostic is
   what stood between CQ and an oracle that computes anything.

   WHAT THE TRACE WITNESSES, in order, and it is the increment's whole claim:
     1. the three chain rails are minted;
     2. the flag is minted from the LAST of them;
     3. the region routes, rotates, routes back, frees its work rail;
     4. the flag STRIP fires — still reading the live sqrt rail;
     5. the chain is uncomputed LIFO (sqrt, fadd, sitofp) and each rail freed;
     6. the flag is freed;
     7. and ONLY THEN does the second cqrt_ry_i32 fire, with nothing allocated
        but the register itself.
   Step 4-before-5 is the ordering the fix exists to produce: discharging at the
   anchor the FORWARD consumers imply would have freed the sqrt rail before the
   strip recomputed the flag from it.

   RAIL LIVENESS AT THE NON-DIAGONAL GATE (the reading the golden cannot do for
   itself): in the trace cqrt_alloc_i32 appears TWICE — the register h0 and the
   region's work rail h5 — and h5 is freed before the strip. At the S-dagger
   cqrt_ry_i32 the only allocated rail is h0. Strict stage 2b (no
   --allow-unproven) confirms the same from the rail side, over the whole MODULE
   rather than the trace: `slice` takes an argument, so clang -O1 keeps it AND
   inlines a copy into main — 4 rail mints, 10 frees, all verified, 0 unproven,
   and the 2 rails left allocated are the two copies' own measured registers.

   IT IS NOT, BY ITSELF, CORRECTNESS EVIDENCE. Read it with the rail-liveness
   reading, strict free-pairing, and the independent adversarial round — the
   bd nepx lesson (a cleared golden once encoded a dephased circuit). */
#include <math.h>

#define CQ_PI 3.14159265358979323846

int slice(int u) {
    int a = cq_theta(u, 0.5);
    if (sqrt((double) a + 3.0) <= 5.0) {
        a = cq_phi(a, CQ_PI);
    }
    a = cq_theta(a, -0.5);
    return cq_measure(a);
}
int main(void) { (void) slice(3); return 0; }
