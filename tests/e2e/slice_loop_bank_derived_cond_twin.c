/* slice_loop_bank_derived_cond_twin.c — the HAND-UNROLLED twin of
 * `slice_loop_bank_derived_cond.c`.  Its golden is BYTE-IDENTICAL to the rolled
 * one's (`e2e-loop-bank-derived-cond-twin-identical`), which is the strongest
 * statement this tree can make about a rolled loop.  It compiled on the ORACLE
 * too; the ROLLED half did not.  Read the rolled file's header for what the pair
 * witnesses and why the DERIVED condition is what makes it a witness at all.
 */
#include "CQ.h"

int main(void) {
    int q = cq_theta(0, 0.7);
    bool k[3];
    int i = 0;
    if ((q >> i) & 1) k[i] = cq_theta(k[i], 0.5); i = i + 1;
    if ((q >> i) & 1) k[i] = cq_theta(k[i], 0.5); i = i + 1;
    if ((q >> i) & 1) k[i] = cq_theta(k[i], 0.5); i = i + 1;
    return cq_measure(k[0]) + cq_measure(k[1]) + cq_measure(k[2]) + cq_measure(q);
}
