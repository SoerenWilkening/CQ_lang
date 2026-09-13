/* r31 — item 1: the 7.4 break escape rail (`OutReg`), measured. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.0);
    int out = 0;
    for (int i = 0; i < 4; ++i) {
        b = cq_theta(b, 0.5);
        if (b) { out = 7; break; }
    }
    return cq_measure(out);
}
