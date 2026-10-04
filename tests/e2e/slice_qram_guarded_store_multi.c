/* slice_qram_guarded_store_multi.c — g5gi e2e golden: TWO separate guarded-store
 * diamonds that SHARE a block —
 *   if (q < 3) { arr[i] = 7; }   if (q < 5) { arr[j] = 8; }
 * The first diamond's merge is the SECOND diamond's Pred. v1 (iw81.7) declined this
 * via the cross-region block-lifetime pre-flight (it marked the first region's
 * MergeBB "doomed" and saw the second reference it). g5gi exempts a GuardedStoreArm's
 * MergeBB from the doomed set — the guarded flatten erases ONLY the Arm block and
 * leaves the merge intact — so the two diamonds are independent and both lower.
 *
 * Each store is guarded on its OWN path-predicate flag; the whole-DAG LIFO uncompute
 * reverses both stores + both flag strips in strict reverse program order (store2
 * before store1; each flag stripped-then-freed after its store-reverse). The single
 * shared array handle is NEVER freed (§2.9). `noinline` keeps the helper separate so
 * the uncompute (gated OFF in main) runs. The only layer that LINKS — it re-proves
 * the guarded-store symbol set composes across two sequential guarded diamonds. */
#include "CQ.h"

__attribute__((noinline))
static int guarded_multi(int seed) {
    int arr[8] = {0};
    int q = seed; cq_theta(&q, 0.5);  /* condition + load index */
    int i = seed + 1; cq_theta(&i, 0.5); /* first tainted store index */
    int j = seed + 2; cq_theta(&j, 0.5); /* second tainted store index */
    if (q < 3) { arr[i] = 7; }        /* first guarded store */
    if (q < 5) { arr[j] = 8; }        /* second guarded store, shares merge1 */
    int v = arr[q];                   /* observed → local array uncomputes */
    return cq_measure(v);
}

int main(void) {
    return guarded_multi(0);
}
