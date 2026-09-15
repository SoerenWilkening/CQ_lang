/* b10 — b07 with `int` cells: the width axis. The cell type IS the rail type,
   so there is no storage-extension cast and no i8/i1 residual. */
#include "CQ.h"
int main(void) {
    int b0[3];
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]);
}
