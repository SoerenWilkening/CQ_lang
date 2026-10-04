/* slice_predmux_inloop_value_diamond_twin.c — the ALREADY-SHIPPED spelling, and
 * the baseline slice_predmux_inloop_value_diamond.c inherits clearance from
 * (bd test_C_libtooling-fn1q increment 3).
 *
 * The identical program written with `?:`. It contains no tainted `br`, so
 * PredMux is never consulted for it: it goes straight to the 4.4
 * `SelectMergeEmit` controlled-copy merge with bd `zujr`'s loop-carried-handle
 * promotion. IT COMPILES ON THE PRE-INCREMENT ORACLE — that is the whole point
 * of the file, and it is what makes `e2e-predmux-inloop-value-diamond-twin-
 * identical` an inheritance rather than a tautology.
 *
 * ⚠ THE TWIN GATE COMPARES LINES 7..118 AFTER A HANDLE RENAME, NOT LINE 1, AND
 * THE REASON FIRST WRITTEN HERE WAS WRONG (Rule-13 round 1 F-7). It said the
 * four `cqrt_alloc_i32(5)` seed mints "come out permuted". MEASURED: lines 1..6
 * are BYTE-IDENTICAL WITH NO RENAME. The mint order is the same; `clang -O1`
 * permutes which VARIABLE each handle then carries, so only the later uses
 * differ. The prologue is skipped because the rename map would rewrite those six
 * rows' own targets and make identical lines differ — and it is skipped by LINE
 * RANGE, not by a wildcard, so nothing can hide there. After the rename the
 * remaining 112 lines are byte-identical.
 *
 * ⚠ DO NOT "SIMPLIFY" THIS FILE, and do not drop it to three variables to make
 * the prologue line up. At three variables -O1 if-converts the SUBJECT too, and
 * the pair stops testing anything.
 */
#include "CQ.h"

volatile int g_seed = 5;

static int slice(void) {
    int q = g_seed; cq_theta(&q, 0.25);
    int A = g_seed, B = g_seed, C = g_seed, D = g_seed;
    for (int i = 0; i < 3; ++i) {
        int a1 = A - 3, b1 = B - 4, c1 = C - 5, d1 = D - 6;
        A = (q > 5) ? a1 : A; B = (q > 5) ? b1 : B;
        C = (q > 5) ? c1 : C; D = (q > 5) ? d1 : D;
    }
    return cq_measure(A) + cq_measure(B) + cq_measure(C) + cq_measure(D);
}

int main(void) { (void)slice(); return 0; }
