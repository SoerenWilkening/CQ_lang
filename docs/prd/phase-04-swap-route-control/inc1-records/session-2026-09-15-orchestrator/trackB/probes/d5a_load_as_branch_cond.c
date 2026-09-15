/* d5a — a bank load used as a BRANCH CONDITION outside the writing loop.
   D5 must refuse it: the condition wire walkers are memory-blind. */
#include "CQ.h"
int main(void) {
    bool b0[3]; int a = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    if (b0[0]) a = 1;
    return a + cq_measure(b0[1]);
}
