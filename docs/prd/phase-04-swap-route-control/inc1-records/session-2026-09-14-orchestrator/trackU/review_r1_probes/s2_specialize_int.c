#include "CQ.h"
__attribute__((noinline)) static int helper(int k) {
    int b;
    b = cq_theta(b, 0.5);
    return b + k;
}
int main(void) {
    int r = helper(3);
    return cq_measure(r);
}
