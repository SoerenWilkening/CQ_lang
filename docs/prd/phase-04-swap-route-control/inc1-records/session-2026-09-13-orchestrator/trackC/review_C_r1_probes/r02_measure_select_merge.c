/* r02 — item 1: measure the %out of a 4.4 select merge (tainted-condition data select). */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int r = (q == 3) ? 7 : 9;
    return cq_measure(r);
}
