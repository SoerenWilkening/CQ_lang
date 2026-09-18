/* ROLLED: the cone shape inside a bounded loop, with a TRAILING NON-DIAGONAL
 * gate on every register the condition reads (standing protocol item 5 / G-13).
 * The cone is INDEX-DEPENDENT (`k*i`) so -O1 cannot rewrite the accumulation to a
 * closed form and delete the loop — bd 46oo: a probe must be checked at STAGE 1
 * for the shape it claims. */
#include "CQ.h"
int k;
static int slice(void) {
    int q = 0; q = cq_theta(q, 0.5);
    int p = 0; p = cq_theta(p, 0.25);
    for (int i = 0; i < 3; ++i) {
        if (q > 5) { p += (k*i + 7) ^ (i+5); }
    }
    q = cq_theta(q, 0.9);          /* trailing NON-DIAGONAL on the condition's register */
    return cq_measure(p) + cq_measure(q);
}
int main(void) { (void)slice(); return 0; }
