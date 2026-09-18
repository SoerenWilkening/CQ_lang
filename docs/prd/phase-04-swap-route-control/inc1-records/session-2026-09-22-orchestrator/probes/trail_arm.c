/* Trailing NON-DIAGONAL gate on the MERGED (arm) register — the register the
 * cone's value actually reaches. This is the route the increment could plausibly
 * affect, unlike a trailing gate on the condition's register (which the 2c
 * condition-wire fence refuses first, identically on both binaries). */
#include "CQ.h"
int k;
static int slice(void) {
    int q = 0; q = cq_theta(q, 0.5);
    int p = 0; p = cq_theta(p, 0.25);
    if (q > 5) { p += (k*3 + 7) ^ 5; }
    p = cq_theta(p, 0.9);          /* trailing NON-DIAGONAL on the MERGE result */
    return cq_measure(p) + cq_measure(q);
}
int main(void) { (void)slice(); return 0; }
