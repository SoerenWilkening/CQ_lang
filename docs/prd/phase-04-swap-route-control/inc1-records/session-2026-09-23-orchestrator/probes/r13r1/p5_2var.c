#include "CQ.h"
static int slice(void) {
    int A = 5, B = 6;
    bool b = 0;
    b = cq_theta(b, 0.5);
    if (b) { A -= 3; B -= 4; }
    b = cq_theta(b, -0.5);
    return cq_measure(A) + cq_measure(B) + cq_measure(b);
}
int main(void) { (void)slice(); return 0; }
