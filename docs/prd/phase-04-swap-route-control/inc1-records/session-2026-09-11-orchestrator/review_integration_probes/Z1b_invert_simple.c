#include "CQ.h"
int main(void) {
    int q = 0;
    cq_invert_begin();
    q = cq_theta(q, 0.5);
    cq_invert_end();
    return cq_measure(q);
}
