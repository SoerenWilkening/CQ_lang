/* slice_qram_read.c — Phase 7.5 Increment 1 e2e smoke: a tainted-index READ of a
 * const-global table (QROM-shaped). `tbl[q]` with a quantum index `q` lowers
 * COHERENTLY to cqrt_qram_alloc_i32 (array-handle birth) + cqrt_qram_load_i32
 * (Toffoli-copy-out), then the loaded value is measured. NO measurement is
 * inserted that the user did not write (Rule 5); the array handle prints `a<N>`.
 * A static-index read would be SROA'd away by clang -O1 and never reach the pass. */
#include "CQ.h"

static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};

int main(void) {
    int q = 0; cq_theta(&q, 0.5); /* tainted index */
    int v = tbl[q];             /* QROM read — coherent table lookup */
    return cq_measure(v);
}
