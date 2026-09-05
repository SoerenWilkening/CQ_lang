/* slice_control_phase_nest.c — bd test_C_libtooling-3qlq Increment 1 (PRD §6.5):
   THE NEST HALF of the nest-vs-`&&` pair.

   SOURCE INTENT:
       if (q == 5) { if (r == 3) cq_phi(0.3); }

   BYTE-IDENTICAL BY CONSTRUCTION to slice_control_phase_andcond.c, and the point
   is that this is a fact about `clang -O1`, not about the lowering: with the
   inner block carrying nothing but a cheap compare and one void call, SimplifyCFG
   folds BOTH spellings to ONE branch on `select i1 %a, i1 %b, false` (PRD §6.1,
   measured 2026-09-05). The pass never sees a nest here. The gate is
   `e2e-phase-nest-andcond-identical`; if it ever goes red, `-O1`'s fold threshold
   moved and the two shapes stopped being the same program — which is a fact worth
   a red test, not a bug in either slice.

   For a nest that DOES survive the fold, see slice_control_phase_nest_deep.c.

   EXPECTED TRACE SHAPE: TWO leaf mints (icmp_eq on q, icmp_eq on r), ONE
   cqrt_toffoli combining them into a fresh |0> conjunction rail, cqrt_rz_i1 on
   THAT rail, then LIFO uncompute — toffoli first, then each leaf strip — and
   three frees. No cswap, no work rail, no `_controlled`. (This is what
   tools/opcode_table.yaml:46 has always said nesting does.)

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P3 (compound condition tree). */

int slice(void) {
    int q = 0;
    int r = 1;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    if (q == 5) {
        if (r == 3) cq_phi(0.3);
    }

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
