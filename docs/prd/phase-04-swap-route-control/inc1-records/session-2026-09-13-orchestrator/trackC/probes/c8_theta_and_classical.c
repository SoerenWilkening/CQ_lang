/* (accept target) a theta-bearing module with BOTH a quantum and a classical
 * measure — the owner's shape without any control flow. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(5, 0.5); int c = 11;
    return cq_measure(q) + cq_measure(c);
}
