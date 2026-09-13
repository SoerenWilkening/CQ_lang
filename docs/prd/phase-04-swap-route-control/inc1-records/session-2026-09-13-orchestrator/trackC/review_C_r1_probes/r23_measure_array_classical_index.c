/* r23 — item 1: a quantum value through a local array at a CLASSICAL index, then measured. */
#include "CQ.h"
__attribute__((noinline)) static int through(int seed) {
    int arr[4] = {0};
    int q = cq_theta(seed, 0.5);
    arr[1] = q;
    return cq_measure(arr[1]);
}
int main(void) { return through(0); }
