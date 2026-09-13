/* the same beta shape with the `a = 2` removed: the UNPEELED twin. */
#include "CQ.h"
int main(void) {
    int  b0 = cq_theta(0, 0.5);
    bool b1 = (b0 == 1);
    if (b0 == 1) { b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1);
}
