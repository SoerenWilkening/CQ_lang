/* round 2 — TWO prep+select pairs chained, each with a trailing kickback, so
   the precedence graph carries two F-M1 edges and two sanctioned chain edges
   and the Kahn order must interleave them without losing source order. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0; bool b2 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }   /* prep 1 */
    if (b1) a -= 1;                            /* select 1 */
    if (a == 4) { cq_phi(0.3); }               /* kickback 1 */
    if (a >= 4) { b2 = cq_theta(b2, 0.25); }   /* prep 2 */
    if (b2) a -= 2;                            /* select 2 */
    if (a == 2) { cq_phi(0.6); }               /* kickback 2 */
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2) + cq_measure(a);
}
