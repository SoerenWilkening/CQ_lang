#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[1000];
    for (int i = 0; i < 1000; ++i) {
        if (a >= 3){
            b0[i] = cq_theta(b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(a);
}
