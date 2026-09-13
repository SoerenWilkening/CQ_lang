/* verdict (c): a CLASSICAL measure inside a TAINTED region's arm. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; int c = 3;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) { a = cq_measure(c); }
    return a + cq_measure(b0);
}
