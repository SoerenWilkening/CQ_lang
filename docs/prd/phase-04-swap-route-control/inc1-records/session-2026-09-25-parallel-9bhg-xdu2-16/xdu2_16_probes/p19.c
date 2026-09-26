#include <stdlib.h>
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;
    for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3;
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
