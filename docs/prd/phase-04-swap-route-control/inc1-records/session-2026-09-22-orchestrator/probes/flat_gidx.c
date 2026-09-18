#include "CQ.h"
int p[8] = {3,2,1,0,0,0,0,0};
int idx;
int main(void) {
    int P = 0; bool b = false;
    b = cq_theta(b, 0.5);
    if (b) { P += p[idx]; }
    return cq_measure(b) + cq_measure(P);
}
