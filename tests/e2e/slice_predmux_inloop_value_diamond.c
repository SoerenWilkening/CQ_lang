/* slice_predmux_inloop_value_diamond.c — bd test_C_libtooling-fn1q increment 3
 * (PredMux E2's in-loop admission). A tainted-condition VALUE diamond lying
 * STRICTLY INSIDE a bounded loop body. Before this increment PredMux's E2 gate
 * refused every region with a block on any CFG cycle, so this declined
 * `cq controlled lowering: control flow under quantum control` while the `?:`
 * spelling of the same program compiled — the whole over-decline.
 *
 * ⚠ FOUR CARRIED VARIABLES, AND THAT IS THE POINT, NOT A ROUND NUMBER. The axis
 * this bead turns on is `br` vs `select` and `clang -O1` picks it. MEASURED on
 * this exact program: at TWO and THREE assignments -O1 if-converts the arm into
 * `select`s and the region never reaches PredMux at all; at FOUR it emits the
 * `br` diamond. Drop a variable and this slice silently stops testing the thing
 * it exists for (bd `46oo` — check a control-flow probe at STAGE 1 for the
 * shape it claims).
 *
 * ⚠ `g_seed` IS `volatile` FOR THE TWIN'S SAKE. With compile-time-constant
 * seeds, `-O1` const-folds the arithmetic and the two spellings stop being the
 * same circuit — the trap this bead's own bisection history records as "THE
 * TWIN PROVES NOTHING".
 *
 * The loop stays ROLLED: the region is flattened, the loop is not. Per trip the
 * emitted stream is the shipped controlled-copy merge, four times — one per
 * carried value — over registers promoted to loop-carried handles by bd `zujr`.
 */
#include "CQ.h"

volatile int g_seed = 5;

static int slice(void) {
    int q = cq_theta(g_seed, 0.25);
    int A = g_seed, B = g_seed, C = g_seed, D = g_seed;
    for (int i = 0; i < 3; ++i) {
        if (q > 5) { A -= 3; B -= 4; C -= 5; D -= 6; }
    }
    return cq_measure(A) + cq_measure(B) + cq_measure(C) + cq_measure(D);
}

int main(void) { (void)slice(); return 0; }
