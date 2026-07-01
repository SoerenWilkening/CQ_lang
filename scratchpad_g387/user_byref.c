#include <CQ.h>
// A USER-written function with a pointer out-param. Body is VISIBLE.
static void mysplit(int v, int *out) {
    *out = v + 7;          // writes a derived value through the pointer
}
int demo(void) {
    int x = cq_theta(0, 0.5);   // x tainted (quantum)
    int e;
    mysplit(x, &e);             // tainted arg + pointer out-param, but we HAVE the body
    return cq_measure(e);
}
