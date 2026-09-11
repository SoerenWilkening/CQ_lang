/* V8 shape with an INT condition: the arm ROTATES the condition register */
#include "CQ.h"
int main(void) {
    int a = 5; int b0 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b0 = cq_theta(b0, 0.9); }
    return cq_measure(b0) + cq_measure(a);
}
