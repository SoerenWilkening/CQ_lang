#include "CQ.h"
int atomic_xchg_error(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int cell = x;
    int old = __atomic_exchange_n(&cell, c, __ATOMIC_SEQ_CST);
    return cq_measure(old) + cq_measure(cell);
}
