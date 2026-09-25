#include <stdlib.h>
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = cq_theta(2, 0.1);
    if ((q > 1) & (a < 5)) a += 3;
    if ((q > 1) & (a < 5)) a += n;
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
