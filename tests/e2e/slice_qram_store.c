/* slice_qram_store.c — Phase 7.5 Increment 2 e2e smoke: an alloca-backed
 * tainted-index STORE + LOAD (Shadow-shaped). `arr[q] = 7` (a tainted store at a
 * quantum index, classical value) followed by `arr[p]` (a tainted-index load)
 * lowers COHERENTLY to cqrt_qram_alloc_i32 (array-handle birth) +
 * cqrt_qram_store_i32 (void in-place on the array handle; the backend owns the
 * per-store tape) + cqrt_qram_load_i32 (Toffoli-copy-out), then the loaded value
 * is measured. The classical store value 7 is materialized into a basis-state
 * handle (cqrt_alloc_i32(7)) so the store's (arr, idx, val) trace stays
 * all-handles. NO measurement is inserted that the user did not write (Rule 5);
 * the array handle prints `a<N>`. A static-index access would be SROA'd away by
 * clang -O1 and never reach the pass — this fires only for the dynamic index.
 * `main` is resident, so the array / rails are reclaimed at process exit (no
 * reversal is emitted — the escaped/observed case, §2.7). */
#include "CQ.h"

int main(void) {
    int arr[8] = {0};
    int q = cq_theta(0, 0.5);   /* tainted index */
    int p = cq_theta(1, 0.5);   /* tainted index */
    arr[q] = 7;                 /* tainted-index store — coherent table write */
    int v = arr[p];             /* tainted-index load  — coherent table read  */
    return cq_measure(v);
}
