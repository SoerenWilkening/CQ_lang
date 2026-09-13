#include "CQ.h"
#include <math.h>
int g;
int main(void) {                      /* arm WRITES MEMORY -> no if-conversion,
                                         so classifyArms sees a phi condition */
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    if (b1) { g = 1; }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a) + g;
}
