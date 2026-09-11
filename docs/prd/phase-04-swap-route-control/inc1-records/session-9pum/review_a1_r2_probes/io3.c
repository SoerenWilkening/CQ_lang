#include <stdio.h>
__attribute__((noinline)) void emit(int seed) {
    int q = cq_theta(seed, 0.5);
    int r = cq_theta(seed, 0.25);
    int r2 = cq_theta(r, 0.9);        /* staler on r's wire, BEFORE the sink */
    if (r > 5) printf("%d", q);
    (void) cq_measure(q);
    (void) cq_measure(r2);
}
int main(void){ emit(7); return 0; }
