/* slice_qram_guarded_store_swapped.c — g5gi e2e golden: a guarded Shadow store on a
 * SWAPPED (FALSE-successor) branch. `clang -O1` canonicalizes `if (q != 3) {...}` to
 * `icmp eq; br eq, %merge, %arm` (Rule 9) — the side-effect-only store arm is the
 * FALSE successor, so the store fires on `¬(q==3)`.
 *
 * g5gi lowers this by a NEGATED MINT: the path-predicate flag is minted with the
 * INVERSE predicate (`icmp eq` → `icmp ne`), so `flag = [q!=3]` fires the guarded
 * store exactly on the taken (false) edge — NO `cqrt_x` bracket. The whole-DAG LIFO
 * uncompute reverses the negated compare via its own `_unc`
 * (cq_template_icmp_ne_i32_hl_unc) IDENTICALLY to the un-negated case; the
 * store-reverse-BEFORE-strip order is preserved. The array handle is never freed
 * (§2.9); NO measurement is inserted the user did not write (Rule 5). `noinline`
 * keeps the helper a separate function under clang -O1 (else the whole-DAG uncompute
 * — gated OFF in main — never runs). This is the only layer that LINKS, re-proving
 * the guarded-store symbol set resolves + signature-matches with the negated flag. */
#include "CQ.h"

__attribute__((noinline))
static int guarded_swapped(int seed) {
    int arr[8] = {0};
    int q = seed; cq_theta(&q, 0.5);  /* condition + load index */
    int i = seed + 1; cq_theta(&i, 0.5); /* tainted store index */
    if (q != 3) { arr[i] = 7; }       /* SWAPPED — store on the FALSE successor */
    int v = arr[q];                   /* observed → local array uncomputes */
    return cq_measure(v);
}

int main(void) {
    return guarded_swapped(0);
}
