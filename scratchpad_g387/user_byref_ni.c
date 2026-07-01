#include <CQ.h>
__attribute__((noinline)) static void mysplit(int v, int *out) { *out = v + 7; }
int demo(void) {
    int x = cq_theta(0, 0.5);
    int e;
    mysplit(x, &e);
    return cq_measure(e);
}
