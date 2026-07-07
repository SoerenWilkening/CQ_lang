/* slice_qram_guarded_store.c — iw81.7 e2e golden: a tainted-index Shadow STORE
 * UNDER tainted control (`if (q < 3) { arr[i] = 7; }`) in a NON-main helper whose
 * array is observed (measured) inside the helper, so the local scratch array MUST
 * uncompute. The store is NOT swap-routable (memory has no per-arm work rail;
 * swap-routing writes arr[0]=0 on the inactive branch) — it is GENUINELY CONTROLLED.
 *
 * Trace shape (the golden contract): the path-predicate flag is minted from the
 * pre-store condition handle (cq_template_icmp_slt_i32_hl), the diamond is FLATTENED,
 * and the store lowers to the GUARDED symbol cqrt_qram_store_i32_controlled(flag,
 * arr, idx, val) (Bennett emit_shadow_store_guarded! — a no-op when flag=0). The
 * post-diamond load arr[q] is UNCONDITIONAL (post-dominates the branch) → accepted as
 * straight-line 7.5. On reversal the guarded store undoes via
 * cqrt_qram_store_i32_controlled_unc(flag, ...) with the flag STILL LIVE (arg 0),
 * THEN the flag is stripped (cq_template_icmp_slt_i32_hl_unc) and freed — the
 * store-reverse-BEFORE-strip order is the pred-lifetime invariant (an ungated /
 * pre-stripped _unc over-pops the inactive branch, a dephasing silent miscompile).
 * The array handle is a classical resource token, never freed (§2.9). NO measurement
 * is inserted that the user did not write (Rule 5). `noinline` keeps the helper a
 * separate function under clang -O1 (else it inlines into main and degenerates into
 * the no-reversal main-resident case). */
#include "CQ.h"

__attribute__((noinline))
static int guarded_local(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);      /* condition + load index */
    int i = cq_theta(seed + 1, 0.5);  /* tainted store index */
    if (q < 3) { arr[i] = 7; }        /* guarded tainted-index store */
    int v = arr[q];                   /* observed → local array uncomputes */
    return cq_measure(v);
}

int main(void) {
    return guarded_local(0);
}
