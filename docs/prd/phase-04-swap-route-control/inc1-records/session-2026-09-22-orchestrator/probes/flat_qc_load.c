#include "CQ.h"
int p[8] = {3,2,1,0,0,0,0,0};
int idx;
int main(void) {
    bool b = false;
    b = cq_theta(b, 0.5);
    int P = b ? 10 : 20;          /* P is quantum */
    bool c = false; c = cq_theta(c, 0.5);
    if (c) { P += p[idx]; }
    return cq_measure(P);
}
