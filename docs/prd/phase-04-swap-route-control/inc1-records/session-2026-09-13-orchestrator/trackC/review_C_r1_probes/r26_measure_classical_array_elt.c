/* r26 — a CLASSICAL array element measured inside a quantum module. */
#include "CQ.h"
__attribute__((noinline)) static int mix(int seed) {
    int arr[4] = {1,2,3,4};
    int q = cq_theta(seed, 0.5);
    return cq_measure(arr[2]) + cq_measure(q);
}
int main(void) { return mix(0); }
