/* t16 rolled — a NARROW (short) loop-carried handle, 3 trips, classical bound. */
#include "CQ.h"
int main(void) {
    short a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return (int)cq_measure(a);
}
