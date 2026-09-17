/* sx5 — the FLAT (loop-free) narrow negative-literal program.  Run on the ORACLE
 * this settles whether the missing-`signext` literal defect was already
 * C-reachable before bd 11qv, or whether bd 11qv is what opens it. */
#include "CQ.h"
int main(void) {
    short a = 5;
    bool b = 0;
    b = cq_theta(b, 0.5);
    if (b) a -= 3;
    return (int)cq_measure(a);
}
