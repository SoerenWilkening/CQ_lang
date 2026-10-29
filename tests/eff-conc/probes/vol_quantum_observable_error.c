#include "CQ.h"
volatile int sink;
void vol_quantum_observable_error(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    sink = x;   /* a quantum value written where the outside can see it */
}
