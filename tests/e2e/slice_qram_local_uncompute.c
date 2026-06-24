/* slice_qram_local_uncompute.c — Phase 7.5 bug sxuk e2e: a LOCAL alloca array
 * built + loaded in a NON-main helper whose loaded value is observed (measured)
 * INSIDE the helper. Unlike slice_qram_store (main-resident, where the array is
 * reclaimed at process exit and nothing reverses), the non-main helper's local
 * scratch array MUST uncompute: the loaded value is copied out to a kept carrier
 * (cqrt_alloc_i32(0) + cqrt_copy_i32) which is what gets measured, then the
 * load+store chain reverses (cqrt_qram_load_i32_unc + cqrt_qram_store_i32_unc),
 * the index rotation rails reverse-play and free, and the array handle is left
 * allocated but clean |0> (a classical resource, never freed). WITHOUT the fix the
 * stores would leak, entangling the measured value with dirty scratch — a
 * dephasing silent miscompile (bug sxuk). `noinline` keeps the helper a separate
 * function under clang -O1 (otherwise it inlines into main and degenerates into
 * the no-reversal main-resident case). NO measurement is inserted that the user
 * did not write (Rule 5). */
#include "CQ.h"

__attribute__((noinline))
static int measured_local(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);      /* tainted index */
    int p = cq_theta(seed + 1, 0.5);  /* tainted index */
    arr[q] = 7;                       /* tainted-index store */
    int v = arr[p];                   /* tainted-index load  */
    return cq_measure(v);             /* observed in a NON-main fn → array uncomputes */
}

int main(void) {
    return measured_local(0);
}
