/* r21 — item 4: a classical measure feeding a tainted-condition select operand. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int c = 9;
    int r = (q == 3) ? cq_measure(c) : 4;
    return r;
}
