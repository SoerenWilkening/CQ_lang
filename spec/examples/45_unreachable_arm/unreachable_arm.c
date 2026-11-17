#include <stdlib.h>
int unreachable_arm(int x0, double th, int k, int c) {
    int x = x0;
    cq_theta(&x, th);
    if (x == k)
        abort();
    return cq_measure(x + c);
}
int abort_then_rotate(int x0, double th, int k, double t2) {
    int x = x0;
    cq_theta(&x, th);
    if (x == k)
        abort();
    cq_theta(&x, t2);
    return cq_measure(x);
}
