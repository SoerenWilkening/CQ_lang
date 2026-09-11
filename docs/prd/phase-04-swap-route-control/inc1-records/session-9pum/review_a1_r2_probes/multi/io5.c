#include <stdio.h>
int ext_f(int a); int opaque(void); int ext(int a);
__attribute__((noinline)) int emit(int seed) {
    int q = cq_theta(seed, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);
    int z = 0; if (opaque()) z = ext(1);
    int b  = cq_theta(y, 0.25);
    int b3 = cq_theta(y, 0.9);
    int t  = cq_theta(seed, 0.2);
    if (b > 1) printf("%d", t);
    return cq_measure(t) + cq_measure(b3) + cq_measure(q) + z;
}
int main(void){ (void) emit(7); return 0; }
