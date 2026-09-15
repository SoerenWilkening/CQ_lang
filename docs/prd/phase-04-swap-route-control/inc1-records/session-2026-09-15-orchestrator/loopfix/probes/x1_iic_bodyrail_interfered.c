/* R13-r2 X1 — clause (ii-c) reached WITH a body rail whose ancestry is `y`,
   and `y` interfered after the loop.  Without (ii-c) the hoisted measure-owned
   `y & 1` refuses the marking and S' declines; with it the loop is marked. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & 1) + cq_measure(y & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
