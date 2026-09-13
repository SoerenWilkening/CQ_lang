#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5;
    bool b[3] = {0,0,0};
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) a -= 3;
    }
    return cq_measure(a) + cq_measure(b[0]) + cq_measure(b[1]) + cq_measure(b[2]);
}
