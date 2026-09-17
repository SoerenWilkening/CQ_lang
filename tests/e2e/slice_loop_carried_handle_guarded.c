// slice_loop_carried_handle_guarded.c — bd `test_C_libtooling-h1ip`, the GUARDED
// loop-carried handle: a RUNTIME TRIP BOUND.
//
// `n` is `argc`, so the trip count is not knowable at compile time and `clang
// -O1` must emit a ZERO-TRIP GUARD.  Until 2026-09-20 this DECLINED
// (`cq loop lowering: loop-carried tainted value crosses iterations`), because
// the promotion minted the trip-1 register in the PREHEADER and the guard's
// false edge bypasses it — so the exit phi muxed the CLASSICAL seed against a
// handle and `loopCarriedHandlePhi` clause (Z8) refused.
//
// OWNER RULING Q1, 2026-09-20: *hoist the alloc above the guard and ACCEPT THE
// DEAD ALLOC*.  The mint point for a guarded loop is the GUARD'S OWN terminator,
// and every out-of-loop phi incoming carrying the SEED on the guard's edge is
// rewritten to that handle.
//
// ⚠ THE ACCEPTED COST, stated so the golden is not misread as free: a loop that
// runs ZERO times still allocates `cqrt_alloc_i32(5)`.  It is left allocated,
// never freed dirty (Rule 6).  On the zero-trip path the exit phi NAMES that
// register and the program measures it — which is the RIGHT ANSWER, since a
// loop that never runs leaves the variable at its seed.  The allocation is not
// merely tolerable there; it is what makes the zero-trip path expressible.
//
// ⚠ THE GOLDEN IS THE ONE-TRIP RUN.  `run_slice.sh` invokes the binary with no
// arguments, so `argc == 1` and the loop runs exactly once.  The ZERO-TRIP and
// TWO-TRIP paths of this same binary were exercised by hand at the landing
// (`probes/h1f_zerotrip.c`): zero trips emits exactly `cqrt_alloc_i32(7)` then
// `cqrt_measure_i32(h0)`, two trips emits the full per-trip chain twice with
// each trip copying out of the previous register.  A golden pins ONE path;
// said out loud rather than left for a reader to assume.
//
// ⚠ AND WHAT THIS SLICE DOES NOT WITNESS: the trailing-non-diagonal-gate hazard
// (bd `s82e`).  Measured separately at the landing — with a trailing
// `cq_theta` on the carried register the ROLLED form DECLINES on both the oracle
// and this binary while the FLAT twin ACCEPTS, so the rolled form is strictly
// MORE conservative and this increment does not widen that class.
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc;               /* RUNTIME trip bound — the compiler cannot know it */
    int acc = 5;
    for (int i = 0; i < n; ++i) {
        bool t = 0;
        t = cq_theta(t, 0.5);
        if (t) acc = 1;
    }
    return cq_measure(acc);
}
