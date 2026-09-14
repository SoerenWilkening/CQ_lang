#include "CQ.h"
/* p1c — in-loop state prep whose condition is minted INSIDE the body (the
   loop-variant condition the P4 prong requires), with a carried bool. */
int main(void) {
    bool q = 0;
    bool v = 0;
    int s = 0;
    for (int i = 0; i < 3; i++) {
        q = cq_theta(q, 0.3);         /* chained, in-body: loop-variant */
        bool b = 0;
        if (q) { b = cq_theta(b, 0.5); }
        s += cq_measure(v);
        v = b;
    }
    return s + cq_measure(q);
}
