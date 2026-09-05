/* 3qlq Inc 1: migrated to register-free cq_phi -- the loop-body `q = cq_phi(q, 0.1)` -> `cq_phi(0.1)`.
   FLAG: this slice IS a rolled loop of uncontrolled Rz. Every one of them is a global
   phase under D2 and is DELETED, so the loop body becomes empty and `-O1` may delete
   the loop itself. Purpose does NOT survive.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_loop_phase_accum.c — Phase 7.3 Inc 1 (799w.1): the rolled-in-place
   Case A phase accumulator e2e golden. A classically-bounded loop over an
   in-place persistent rail lowers ROLLED — the loop CFG is preserved, the body
   emits `cqrt_rz` in place over a loop-invariant handle, the loop-carried header
   phi AND the zero-trip/exit merge phi collapse to the single rail, ZERO
   measurements inserted, ZERO in-body frees. The golden trace (running the rolled
   loop a FIXED 3 times) is BYTE-IDENTICAL to the manually-unrolled 3×cqrt_rz form
   — the PRD §4 done-criterion.

   The bound `n` is a RUNTIME parameter (the harder A2 shape: clang -O1 emits the
   zero-trip guard + the exit merge phi), passed a fixed 3 from main so the trace
   is deterministic. `noinline` keeps the function boundary so clang -O1 lowers
   the rolled loop directly (it never unrolls the opaque cq_phi body). cq_theta/
   cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
__attribute__((noinline))
double accum(double seed, int n) {
    double q = cq_theta(seed, 0.5);
    for (int i = 0; i < n; i++)
        cq_phi(0.1);          /* in-place Rz on the loop-invariant rail */
    return cq_measure(q);
}
int main(void) { (void) accum(0.25, 3); return 0; }
