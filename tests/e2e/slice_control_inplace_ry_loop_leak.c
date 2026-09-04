/* slice_control_inplace_ry_loop_leak.c — bd test_C_libtooling-drbq Increment 3,
 * round-1 lens L3 Q1. THE O(K) FREEZE LEAK, MEASURED.
 *
 * PRD §13.5 says the Increment-1 structural freeze (a rail carrying a controlled
 * rotation is `NotClosed`, never reverse-played, never freed) costs "K rails at
 * run time" when the body DERIVES anything from the frozen register — one leaked
 * template rail per activation per derivation, linear in the trip count. Until
 * this slice that claim was ANALYTIC: no shipped slice read the rotated register
 * inside the body, because the obvious spellings are refused (a read AFTER the
 * region is `cq opcode lowering: operand predates a non-diagonal gate`; a read in
 * a SECOND loop is a classical-condition mux).
 *
 * The one spelling that works is to read the register BEFORE the region in the
 * same body: the read then precedes that activation's own relabelling gate, and
 * the back edge does not stale it because the loop-carried `r` phi crosses a real
 * rail gate every trip (the 8h7d.5 F-2 refresh rule).
 *
 * MEASURED (K=2 here; L3 also ran K=3): per activation the body emits
 *     cq_template_mul_i32_hl(hR, 7) -> hS      <- entangled with the FROZEN r
 *     cqrt_tape_write_i32(t0, hS)  -> hT       <- second rail
 * and NOTHING EVER FREES EITHER. 2 leaked template rails per activation — 4 at
 * K=2, 6 at K=3 — while the only `cqrt_free` per trip is the region's own flag.
 *
 * IT IS RULE-6 CORRECT AND IT IS NOT A REGRESSION. Every leaked rail is LEFT
 * ALLOCATED; none is freed dirty. Strict stage 2b is BLIND to it by construction
 * (its census counts `cqrt_alloc` mints and these rails are TEMPLATE-minted —
 * read that checker's header), which is exactly why the claim needs a golden and
 * a twin rather than a gate.
 *
 * AND THE TWIN LEAKS THE SAME RAILS FOR THE SAME REASON, which is the point of
 * the pair: `..._leak_unrolled.c` is byte-identical (ctest
 * `e2e-inplace-ry-loop-leak-twin-identical`). The cost is the FREEZE's, not the
 * ROLL's — a reader who sees 2K stranded rails must not conclude the loop
 * lowering invented them.
 *
 * ORACLE: the rolled form DECLINES on the pre-Increment-3 binary (`control flow
 * inside a loop body under quantum control`); the flat twin lowers identically on
 * both. So this slice is Increment 3's own new population.
 */
#include <stdio.h>

int slice(void) {
    int q = 0; int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    for (int i = 0; i < 2; ++i) {
        int s = r * 7;
        printf("%d\n", s);
        if (q == 5) { r = cq_theta(r, 0.9); }
        q = cq_phi(q, 0.1);
    }
    return cq_measure(q) + cq_measure(r);
}

int main(void) { (void)slice(); return 0; }
