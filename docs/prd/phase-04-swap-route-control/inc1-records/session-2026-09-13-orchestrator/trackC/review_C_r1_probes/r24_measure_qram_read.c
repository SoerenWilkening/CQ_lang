/* r24 — item 1: a QRAM read at a TAINTED index, measured (the QramLowering %out RAUW). */
#include "CQ.h"
__attribute__((noinline)) static int qread(int seed) {
    int arr[8] = {0,1,2,3,4,5,6,7};
    int q = cq_theta(seed, 0.5);
    int v = arr[q];
    return cq_measure(v);
}
int main(void) { return qread(0); }
