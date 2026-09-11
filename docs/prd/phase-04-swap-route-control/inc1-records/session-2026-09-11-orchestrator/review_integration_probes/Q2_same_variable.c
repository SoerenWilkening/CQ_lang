/* b0 and b1 are the SAME variable: the condition rail is also the prep target */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    return cq_measure(b0)+cq_measure(a);
}
