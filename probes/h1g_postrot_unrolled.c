#include "CQ.h"
int main(void) {
    int acc = 5;
    bool t0 = 0;
    t0 = cq_theta(t0, 0.5);
    if (acc >= 3) t0 = cq_theta(t0, 0.25);
    if (t0) acc -= 3;
    bool t1 = 0;
    t1 = cq_theta(t1, 0.5);
    if (acc >= 3) t1 = cq_theta(t1, 0.25);
    if (t1) acc -= 3;
    acc = cq_theta(acc, 0.9);
    return cq_measure(acc);
}
