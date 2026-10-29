#include "CQ.h"
int atomicrmw_error(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int cell = x;
    __atomic_fetch_add(&cell, c, __ATOMIC_SEQ_CST);
    return cq_measure(cell);
}
