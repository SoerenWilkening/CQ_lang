/* slice_qram_guarded_store_fp.c — bd 38t2 e2e (Rule-13 clearance link-proof):
 * the FP twin of slice_qram_guarded_store.c — a tainted-index fp Shadow STORE
 * UNDER tainted control (`if (q < 3) { arr[i] = 7.0; }`) in a NON-main helper
 * whose array is observed inside the helper, so the local scratch MUST uncompute.
 * This golden LINKS the guarded fp family end-to-end: the path-predicate flag is
 * minted (cq_template_icmp_slt_i32_hl), the diamond flattens, the store lowers to
 * cqrt_qram_store_f64_controlled(flag, arr, idx, val), the post-diamond load
 * copies out to a kept carrier via cqrt_copy_f64, and on reversal the guarded
 * store undoes via cqrt_qram_store_f64_controlled_unc with the flag STILL LIVE
 * (arg 0), THEN the flag is stripped — the store-reverse-BEFORE-strip
 * pred-lifetime invariant, byte-diffed through a real link (Rule 2). The array
 * handle is a classical resource token, never freed (§2.9). `noinline` keeps the
 * helper a separate function under clang -O1. NO measurement is inserted that the
 * user did not write (Rule 5). */
#include "CQ.h"

__attribute__((noinline))
static double guarded_local_fp(int seed) {
    double arr[8] = {0};
    int q = cq_theta(seed, 0.5);      /* condition + load index */
    int i = cq_theta(seed + 1, 0.5);  /* tainted store index */
    if (q < 3) { arr[i] = 7.0; }      /* guarded tainted-index fp store */
    double v = arr[q];                /* observed → local array uncomputes */
    return cq_measure(v);
}

int main(void) {
    return (int)guarded_local_fp(0);
}
