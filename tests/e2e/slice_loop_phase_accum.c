/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, finding F-B2-3 / prep-b2, orchestrator remedy).
   The golden below is a NEW PROGRAM's trace, not an audit substitution of the old
   one, and it is recorded as such in
   docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md §12.

     OLD: for (i = 0; i < n; i++) cq_phi(0.1);          (an UNCONTROLLED Rz body)
     NEW: for (i = 0; i < n; i++) { if (q == 2.0) cq_phi(0.1);
                                    cq_theta(&q, 0.05); }

   WHY. Under owner decision D2 an uncontrolled `cq_phi` is a GLOBAL PHASE and is
   DELETED, and this slice's ENTIRE loop body was one such call — so the body
   became empty. MEASURED before this rewrite: the golden went from 3 `cqrt_rz`
   lines to ZERO and read, in full, `alloc; ry; measure`. There was no loop left
   in it to be rolled, and the header's own done-criterion ("BYTE-IDENTICAL to the
   manually-unrolled form") had nothing to compare. That is the bd `3c6m.63` /
   `165/174` failure mode — a test that still passes and no longer measures its
   own subject — and it is invisible to a green suite.

   WHAT THE NEW BODY IS. The register-free equivalent of "accumulate a phase per
   iteration" is a per-iteration BRANCH phase by KICKBACK: the compare mints a flag
   into a |0> ancilla, `cqrt_rz_i1` puts the phase on the marked branch, the
   compare `_unc` returns the flag to |0> and it is freed — all INSIDE the
   iteration, so nothing dirty crosses the back edge and stage 2b runs STRICT.

   ⚠ THE TRAILING `cq_theta` IS LOAD-BEARING, NOT DECORATION. With no gate on `q`
   in the body the condition register is LOOP-INVARIANT, `clang -O1` LICM-hoists
   the `fcmp` into the preheader, and `condWireDisposition`'s P4 precondition
   declines the whole program with `condition predates a non-diagonal gate` (the
   drbq.12 / CLAUDE.md "row W" over-decline, which is arm-class-independent and
   identical on the pre-3qlq oracle). The rotation is what keeps `q` loop-VARIANT,
   and it is exactly the shape the drbq Inc-3 Grover customer has.

   WHAT IT STILL PINS (unchanged from the original done-criterion). The bound `n`
   is a RUNTIME parameter — the harder A2 shape, where `clang -O1` emits the
   zero-trip guard and the exit merge phi — passed a fixed 3 from main so the trace
   is deterministic. The loop lowers ROLLED (the CFG is preserved, the persistent
   f64 rail is collapsed, ZERO measurements are inserted) and the trace is
   BYTE-IDENTICAL to the hand-unrolled `slice_loop_phase_accum_unrolled.c`, which
   has no loop at all. That is now a real ctest gate — `e2e-loop-phase-accum-twin-identical`,
   a `cmp` over the two committed goldens — where before it was a claim in prose.
   `noinline` keeps the function boundary so `clang -O1` lowers the rolled loop
   directly. cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by
   run_slice.sh. */
__attribute__((noinline))
double accum(double seed, int n) {
    double q = seed; cq_theta(&q, 0.5);
    for (int i = 0; i < n; i++) {
        if (q == 2.0) cq_phi(0.1);   /* the per-iteration BRANCH phase (kickback) */
        cq_theta(&q, 0.05);          /* keeps the condition register loop-VARIANT */
    }
    return cq_measure(q);
}
int main(void) { (void) accum(0.25, 3); return 0; }
