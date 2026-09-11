#include <stdio.h>
int ext_f(int a); int opaque(void); int ext(int a);
__attribute__((noinline)) int emit(int seed) {
    int q = cq_theta(seed, 0.5);
    int r = cq_theta(seed, 0.25);
    int r2 = cq_theta(r, 0.9);
    int z = 0; if (opaque()) z = ext(1);
    if (r > 5) printf("%d", q);
    return cq_measure(q) + cq_measure(r2) + z;
}
int main(void){ (void) emit(7); return 0; }
