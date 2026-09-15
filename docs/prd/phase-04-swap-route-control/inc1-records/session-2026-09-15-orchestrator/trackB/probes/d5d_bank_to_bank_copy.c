/* d5d — allow-list entry (3): a further store into a rail-bank cell. */
#include "CQ.h"
int main(void) {
    bool b0[3]; bool b1[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) b1[i] = b0[i];
    for (int i = 0; i < 3; ++i) s += cq_measure(b1[i]);
    return s;
}
