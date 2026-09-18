#include "CQ.h"
int main(void) {
    int A=5,B=6; bool b = false;
    b = cq_theta(b, 0.5);
    if (b) { A -= 3; B -= 4; }
    return cq_measure(A)+cq_measure(B)+cq_measure(b);
}
