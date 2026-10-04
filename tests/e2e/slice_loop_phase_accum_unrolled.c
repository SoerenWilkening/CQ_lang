/* slice_loop_phase_accum_unrolled.c — the HAND-UNROLLED twin of
   slice_loop_phase_accum.c (3qlq Inc 1, finding F-B2-3 / prep-b2). Same body,
   three times, no loop at all.

   Its golden must be BYTE-IDENTICAL to the rolled slice's; the ctest gate is
   `e2e-loop-phase-accum-twin-identical` (a `cmp` over two committed goldens — no
   clang, no opt, no plugin, milliseconds). Byte identity is the strongest witness
   available to a project with no simulator (Rule 2): it says the ROLLED form emits
   the same unitary, gate for gate and handle for handle, as a stream with no back
   edge in it. The rolled slice's header carried that as a CLAIM in prose since
   Phase 7.3 Inc 1 and there was no twin in the tree to check it against; this file
   is that twin.

   Do NOT merge this into a shared header with the rolled slice: the whole value is
   that the two files reach the pass through DIFFERENT `clang -O1` output — a
   rotated loop with a zero-trip guard, a header phi and an in-body diamond on one
   side, straight-line code with three diamonds on the other — and converge on one
   gate stream. Sharing the source would test nothing.

   The seed and the angles are the rolled slice's verbatim, and the bound is its
   `main`'s (3). */

/* One loop-body activation of slice_loop_phase_accum.c, verbatim. */
#define CQ_ACCUM_ITER                       \
    if (q == 2.0) cq_phi(0.1);              \
    cq_theta(&q, 0.05);

__attribute__((noinline))
double accum(double seed) {
    double q = seed; cq_theta(&q, 0.5);

    CQ_ACCUM_ITER
    CQ_ACCUM_ITER
    CQ_ACCUM_ITER

    return cq_measure(q);
}
int main(void) { (void) accum(0.25); return 0; }
