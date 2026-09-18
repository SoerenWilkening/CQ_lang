#include "CQ.h"
volatile int g = 5;
#define TRIP if (q > 5) { A -= 3; B -= 4; C -= 5; D -= 6; }
static int slice(void) {
    int q = cq_theta(g, 0.25);
    int A = g, B = g, C = g, D = g;
    TRIP TRIP TRIP
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(A) + cq_measure(B) + cq_measure(C) + cq_measure(D);
}
int main(void){(void)slice();return 0;}
