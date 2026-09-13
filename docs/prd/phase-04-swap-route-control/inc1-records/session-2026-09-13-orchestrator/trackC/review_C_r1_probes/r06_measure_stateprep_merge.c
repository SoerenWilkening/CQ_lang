/* r06 — item 1: measure the merge of a controlled STATE PREP (M-beta). */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = 7;
    if (b) r = cq_theta(7, 0.5);
    return cq_measure(r) + cq_measure(b);
}
