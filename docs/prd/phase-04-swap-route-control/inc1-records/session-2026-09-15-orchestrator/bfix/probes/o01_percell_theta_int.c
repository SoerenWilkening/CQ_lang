/* o01 — THE CAPABILITY, POSITIVE CONTROL (owner constraint relayed 2026-09-15).
   A DISTINCT THETA PER CELL: each cell's rail is minted INSIDE the walk loop,
   per trip.  This is what the rail bank exists for and it must keep ACCEPTING.
   Not the P1 probe's shape: no register's name is parked in more than one cell. */
#include "CQ.h"
int main(void) {
    int b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
