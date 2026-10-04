/* slice_qram_store_computed_index.c — bd test_C_libtooling-r2j3.1 e2e golden.
 *
 * main-resident, so no QRAM store is ever reversed. Two stores read COMPUTED
 * rails: `arr[q & 7] = r + 1` (an `and_i32_hl` index and an `add_i32_hl` value)
 * and the guarded `if (c < 3) arr[i] = 7` (an `icmp_slt_i32_hl` path flag). Each
 * source is then rotated back by a chained cq_theta.
 *
 * Before the fix those three rails were never discharged: each stood allocated as
 * a live CNOT copy of its source across the source's chained Ry, so the rotation
 * acted on a register entangled with the copy (the source program returns q, r and
 * c to their initial basis states; the circuit measured them at random). Golden
 * contract now: every computed rail a store reads is `_unc`'d and freed right
 * after that store, against its un-rotated source, BEFORE the chained Ry on it
 * (`ChainWalk::isInteriorConsumer` clause (b″); the M-B interior partition). The
 * stores themselves are never reversed and the array handle is never freed. */
#include "CQ.h"

int main(void) {
    int arr[8] = {0};
    int q = 0; cq_theta(&q, 0.5);
    int r = 1; cq_theta(&r, 0.5);
    arr[q & 7] = r + 1;              /* computed index AND computed value */
    int c = 2; cq_theta(&c, 0.5);
    int i = 3; cq_theta(&i, 0.5);
    if (c < 3) arr[i] = 7;           /* guarded store: computed path flag */
    int p = 4; cq_theta(&p, 0.5);
    int v = arr[p & 7];
    cq_theta(&q, -0.5);              /* every source rotated back */
    cq_theta(&r, -0.5);
    cq_theta(&c, -0.5);
    return cq_measure(q) + cq_measure(r) + cq_measure(c) + cq_measure(v)
         + cq_measure(i);
}
