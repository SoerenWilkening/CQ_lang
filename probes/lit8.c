#include "CQ.h"
int main(void) {
    char q = 0;
    q = cq_theta(q, 0.5);
    q = q - 3;
    return (int)cq_measure(q);
}
