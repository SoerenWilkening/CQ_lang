/* slice_control_phase_nest_deep.c — bd test_C_libtooling-3qlq Increment 1
   (PRD §6.5): A GENUINE DEPTH-2 NEST — one that survives SimplifyCFG's fold
   threshold, so the pass really does see two regions.

   SOURCE INTENT:
       if (q == 5) {
           s = cq_theta(s, 0.7);        <-- a gate on a THIRD register, in the
                                            outer arm, BEFORE the inner compare
           if (r == 3) cq_phi(0.3);
       }

   WHY THE `cq_theta` IS NOT DECORATION. slice_control_phase_nest.c measures the
   fact that `clang -O1` folds `if(a){if(b) cq_phi(t);}` to ONE branch on
   `select i1 %a, i1 %b, false` — the inner block is too cheap to keep. Putting a
   real call in the outer arm pushes the block over that threshold, so the nest
   arrives as a nest and PRD §6.2 P4 (the 4.3 `RegionTreeDetect` path, with
   `NestedRouteEmit`'s cswap route replaced by P3's conjunction flag) is what has
   to lower it. Without this slice the P4 row has no e2e customer at all and the
   nest-vs-`&&` pair would silently be testing ONE shape twice.

   EXPECTED TRACE SHAPE: outer mint on q; the outer arm's cqrt_ry on s; inner mint
   on r; ONE cqrt_toffoli into a fresh |0> conjunction rail; cqrt_rz_i1 on that
   rail; LIFO uncompute (toffoli, then the inner strip, then the outer strip);
   three frees. No cswap, no work rail, no `_controlled`.

   ⚠ FLAG — THE MEASURED SHAPE IS A *MIXED* NEST, AND WHICH ROW IT LANDS IN IS NOT
   THIS SLICE'S CALL. `clang -O1` gives (measured 2026-09-05):
       %4 = icmp eq i32 %1, 5 ; br i1 %4
       5:  %6 = cq_theta_si32(%3, 0.7) ; %7 = icmp eq i32 %2, 3 ; br i1 %7
       8:  call void @cq_phi(0.3)
       9:  %10 = phi i32 [ %6, %8 ], [ %6, %5 ], [ %3, %0 ]
   — so the OUTER arm carries an **Ry on a third register** (the drbq Inc-3
   controlled-in-place path) and the INNER arm carries the phase. PRD §6.2 P4 is
   written for the 4.3 HOMOGENEOUS-phase nest; PRD §6.3 declines "mixed arms:
   cq_phi beside a value op or an Ry in the same arm". Both readings are available
   and they disagree. The oracle's own word for it today is `impure phase arm`.
   NOTE the homogeneous genuine nest is ALREADY covered by the migrated
   slice_control_nested_phase.c (`if (q > 5) { cq_phi(0.25); if (q < 9) cq_phi(0.75); }`),
   so what this slice uniquely adds IS the mixed combination. Owner/implementer call.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: impure phase arm under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P4 (genuine depth-2 nest). */

int slice(void) {
    int q = 0;
    int r = 1;
    int s = 2;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    s = cq_theta(s, 0.125);

    if (q == 5) {
        s = cq_theta(s, 0.7);
        if (r == 3) cq_phi(0.3);
    }

    return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
