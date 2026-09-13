/* r25 — item 1: the shadow-memory guarded-store carrier, measured. */
#include "CQ.h"
__attribute__((noinline)) static int guarded(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);
    int i = cq_theta(seed + 1, 0.5);
    if (q < 3) { arr[i] = 7; }
    int v = arr[q];
    return cq_measure(v);
}
int main(void) { return guarded(0); }
