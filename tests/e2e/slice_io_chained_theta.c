/* bd 261j(a) — a CHAINED `cq_theta` puts `cqrt_ry` on a DERIVED rail.

   This is the SECOND live instance of the record-freeze defect, found while
   implementing the ruling for the first (slice_io), and it is the reason the
   shipped rule freezes RAILS rather than correlated ROOTS. `RotationLowering`
   emits the second rotation on the EXISTING handle it is handed; here that handle
   is a `cq_template_add_i32_hl` producer's result, so the defective free landed on
   a rail that is not a root and every roots-only formulation would leave it
   standing.

   MEASURED against the shipped pass before the fix (EXIT=0, no diagnostic):
       cqrt_ry_i32(h_op, -0.25); cq_template_add_i32_hl_unc(h_op, h, 1);
       cqrt_free(h_op); cqrt_ry_i32(h, -0.5); cqrt_free(h)
   — TWO defective frees, and stage 2b (free_pairing_check.py) certified BOTH, via
   two DIFFERENT proof rules: `T1-unc-reversal` for h_op and
   `A2-reduces-to-identity` for h. That is also the correction to bd 261j(b): the
   checker tightening is not an A2-only change.

   Under the ruling: the tape write RECORDS h_op; the backward closure over the DAG
   ancestor edges reaches h; and BOTH carry a `cqrt_ry` whose only other operand is
   a classical angle (Rule 3), so neither chain is a basis permutation of anything
   still live. Both freeze — which means NO FREE, left allocated (Rule 6's
   fallback). Both are still fully reverse-played: the golden below carries the
   whole adjoint stream and simply ends without a `cqrt_free`. That distinction is
   the fix's soundness argument, not a detail — see
   ir-pass/test/lowering_io_tape_interleaved_rotation.ll.

   Contrast tests/e2e/slice_io.c (one rail, a root) and the lit fixture
   ir-pass/test/lowering_io_tape_derived_uncompute.ll (a derived rail with NO
   rotation on it, which still reverses and frees — the per-rail discrimination).

   `noinline` is LOAD-BEARING for the same reason as slice_io.c: whole-DAG
   uncompute is gated OFF in `main`, and -O1 would otherwise inline `emit` away.
   cq_theta resolves from CQ.h (force-included); printf from stdio. */
#include <stdio.h>

__attribute__((noinline)) void emit(int seed) {
    int x = cq_theta(seed, 0.5);
    int y = x + 1;
    int z = cq_theta(y, 0.25);
    printf("%d", z);
}

int main(void) {
    emit(4);
    return 0;
}
