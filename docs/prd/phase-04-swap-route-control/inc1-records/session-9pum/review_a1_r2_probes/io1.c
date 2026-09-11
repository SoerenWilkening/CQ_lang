#include <stdio.h>
__attribute__((noinline)) void emit(int seed) {
    int q = cq_theta(seed, 0.5);
    int m = cq_measure(q);
    if (q > 5) printf("%d", q);
    (void) m;
}
int main(void){ emit(7); return 0; }
