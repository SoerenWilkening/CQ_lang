/* o02 — the `_Bool` spelling of o01 (the owner's own cell type). MUST ACCEPT. */
#include "CQ.h"
int main(void) {
    bool b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
