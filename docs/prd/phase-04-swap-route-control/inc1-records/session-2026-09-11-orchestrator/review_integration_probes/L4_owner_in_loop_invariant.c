#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0; int acc = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    for (int i = 0; i < 2; ++i) {
        int aa = a;
        if (b0 == 1) aa -= 3;
        if (aa >= 3){ b1 = cq_theta(b1, 0.5); }
        acc += cq_measure(aa);
    }
    return acc + cq_measure(b0) + cq_measure(b1);
}
