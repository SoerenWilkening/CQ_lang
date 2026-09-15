/* F-5 probe b: the undef classical measure FIRST, before the bank exists. */
#include "CQ.h"
int slice(void) {
    bool b0[3];
    int u;
    int s = cq_measure(u);
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
int main(void) { (void) slice(); return 0; }
