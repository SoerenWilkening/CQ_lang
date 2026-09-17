/* ATTACK A3 on the c1 conversion: THE SAME SHAPE ONE LOOP DEEPER.  c1's loop is
   now the INNER loop of a classical outer one; the interference is after both. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i)
        for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
