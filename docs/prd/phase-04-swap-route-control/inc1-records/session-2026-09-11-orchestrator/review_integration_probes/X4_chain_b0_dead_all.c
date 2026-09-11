/* everything the region touches is dead except the mux */
#include "CQ.h"
int main(void) {
    bool t  = cq_theta((bool)0, 0.1);
    bool b0 = cq_theta(t, 0.5);
    int a = 5; bool b1 = 0;
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(a);
}
