/* slice_qram_local_uncompute_fp.c — bd 38t2 e2e (Rule-13 clearance link-proof):
 * the FP twin of slice_qram_local_uncompute.c. A LOCAL `double` alloca array
 * built + loaded in a NON-main helper whose loaded value is measured INSIDE the
 * helper, so the local scratch MUST uncompute. This is the golden that LINKS the
 * fp reversal family end-to-end (Rule 2: e2e is the only layer proving every
 * emitted symbol resolves and signature-matches): the loaded value copies out to a
 * kept carrier via the UNCONTROLLED fp copy (cqrt_alloc_f64(0) + cqrt_copy_f64 —
 * the frozen-designate symbol minted by emitCopyOutIfDirectMeasure), then the
 * load+store chain reverses (cqrt_qram_load_f64_unc + cqrt_qram_store_f64_unc,
 * faithful Bennett LIFO: store_unc BEFORE the index rails' Ry† + free), and the
 * array handle is left allocated but clean |0> (a classical resource, never
 * freed). `noinline` keeps the helper a separate function under clang -O1 (else it
 * inlines into main and degenerates into the no-reversal main-resident case). NO
 * measurement is inserted that the user did not write (Rule 5). */
#include "CQ.h"

__attribute__((noinline))
static double measured_local_fp(int seed) {
    double arr[8] = {0};
    int q = cq_theta(seed, 0.5);      /* tainted index */
    int p = cq_theta(seed + 1, 0.5);  /* tainted index */
    arr[q] = 7.0;                     /* tainted-index fp store */
    double v = arr[p];                /* tainted-index fp load  */
    return cq_measure(v);             /* observed in a NON-main fn → array uncomputes */
}

int main(void) {
    return (int)measured_local_fp(0);
}
