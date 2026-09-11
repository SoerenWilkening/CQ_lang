#include <stdio.h>
__attribute__((noinline))
static int guarded_local(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);
    int i = cq_theta(seed + 1, 0.5);
    int m = 5, n = 6;
    if (q < 3) { arr[i] = 7; m = 1; n = 2; }
    int v = arr[q];
    return cq_measure(v) + cq_measure(m) + cq_measure(n);
}
int main(void){ printf("%d\n", guarded_local(0)); return 0; }
