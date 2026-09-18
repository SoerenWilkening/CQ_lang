#include "CQ.h"
int k;
int main(void) {
    bool b = false; b = cq_theta(b, 0.5);
    int P = b ? 10 : 20;
    bool c = false; c = cq_theta(c, 0.5);
    int t = (k*3 + 7) ^ 5;
    if (c) { P += t; }
    return cq_measure(P);
}
