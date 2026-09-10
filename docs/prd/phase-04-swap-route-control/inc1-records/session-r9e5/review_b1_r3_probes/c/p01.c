/* p01 — AREA 1: a tainted-index GUARDED STORE under a BARE RAIL condition
   (`GuardedStoreArmEmit`, the 7.5 iw81.7 shape). It is not one of the four
   recording sites; if it mints a flag from a rail and reads the register, the
   window is open one consumer over. */
#include "CQ.h"
__attribute__((noinline))
static int guarded_local(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);
    int i = cq_theta(seed + 1, 0.5);
    _Bool b = cq_theta((_Bool)(seed & 1), 0.25);
    if (b) { arr[i] = 7; }
    int v = arr[q];
    return cq_measure(v);
}
int main(void) { return guarded_local(1); }
