/* slice_qram_load_index_record_window.c — bd test_C_libtooling-r2j3.3 e2e golden
 * (the compiler half).
 *
 * `defect`: a QROM read `v = tbl[b]` (distinct entries), then a chained cq_theta
 * on the index `b`, then `printf` of b and v. The tape records b's label AFTER
 * the Ry and BEFORE the spine's reverse-play re-applies the inverse Ry, so that
 * inverse does not restore b, `cqrt_qram_load_i32_unc` recomputes tbl[b] from the
 * wrong label, and the load rail is NOT |0>. Golden contract: every adjoint is
 * still emitted, but the load rail gets NO cqrt_free (left allocated, Rule 6);
 * before the fix it was freed — a hidden measurement that stage 2b certified.
 *
 * `only_v`: the control. Only v is printed, so no record sees b's post-Ry label,
 * the inverse Ry restores b exactly, and the load rail IS freed after its _unc.
 * `noinline` keeps both helpers out of main (main reverses nothing). */
#include "CQ.h"
#include <stdio.h>

static const int tbl[8] = {3, 1, 4, 7, 5, 9, 2, 6};

__attribute__((noinline)) static int defect(int u) {
    _Bool b = cq_theta(u, 0.5);
    int v = tbl[b];
    b = cq_theta(b, -0.5);
    printf("%d %d\n", b, v);
    return 0;
}

__attribute__((noinline)) static int only_v(int u) {
    _Bool b = cq_theta(u, 0.5);
    int v = tbl[b];
    b = cq_theta(b, -0.5);
    printf("%d\n", v);
    return 0;
}

int main(void) {
    return defect(1) + only_v(1);
}
