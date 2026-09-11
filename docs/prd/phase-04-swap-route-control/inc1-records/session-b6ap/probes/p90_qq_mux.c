/* extra phi over TWO TAINTED registers (a no-cloning data mux), + prep phi */
#include "CQ.h"
int main(void) {
    int p = cq_theta(0, 0.3);
    int b0 = cq_theta(0, 0.5);
    int a = p; int b1 = 0;
    if (b0 == 1) a = p + 3;
    if (b0 != 1) b1 = cq_theta(b1, 0.5);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
