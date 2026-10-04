/* the `int`-cell spelling of the capability. */
#include "CQ.h"
int slice(void) {
    int b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) cq_theta(&b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
int main(void) { (void) slice(); return 0; }
