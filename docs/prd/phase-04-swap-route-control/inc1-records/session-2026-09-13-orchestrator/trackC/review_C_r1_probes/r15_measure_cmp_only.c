/* r15 — control: a tainted compare with NO control region at all, measured. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    bool c = (q == 3);
    return cq_measure(c);
}
