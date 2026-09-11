/* CONTROL for g01: the shipped guarded-store shape + two EXTRA measured
   registers (no merge phi at all).  If the oracle still runs the whole 7.5
   reversal here, g01's missing reversal belongs to the peel's new accept. */
#include <stdio.h>
__attribute__((noinline))
static int guarded_local(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);
    int i = cq_theta(seed + 1, 0.5);
    int m = cq_theta(seed + 2, 0.5);
    int n = cq_theta(seed + 3, 0.5);
    if (q < 3) { arr[i] = 7; }
    int v = arr[q];
    return cq_measure(v) + cq_measure(m) + cq_measure(n);
}
int main(void){ printf("%d\n", guarded_local(0)); return 0; }
