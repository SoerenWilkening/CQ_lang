/* slice_control_phase_andcond.c — bd test_C_libtooling-3qlq Increment 1
   (PRD §6.5): THE `&&` HALF of the nest-vs-`&&` pair.

   SOURCE INTENT:
       if (q == 5 && r == 3) cq_phi(0.3);

   Its golden must be BYTE-IDENTICAL to slice_control_phase_nest.c's; the ctest
   gate is `e2e-phase-nest-andcond-identical`. See that file's header for why the
   identity is a statement about `clang -O1` (both spellings fold to ONE branch on
   `select i1 %a, i1 %b, false`, PRD §6.1) rather than about the lowering.

   Everything else — the register seeds, the two theta angles, the phase angle and
   the measured expression — is deliberately character-for-character the same as
   the nest slice, because a twin gate over two goldens is only as strong as the
   sameness of everything the twin is not about.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P3 (compound condition tree). */

int slice(void) {
    int q = 0;
    int r = 1;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);

    if (q == 5 && r == 3) cq_phi(0.3);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
