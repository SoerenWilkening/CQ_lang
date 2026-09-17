/* IS IT THE BREAK, OR ANY TWO-BLOCK MARKED BODY?  Same rail, two body blocks made
   by a CLASSICAL `if` that RE-JOINS inside the loop — NO early exit at all. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k < lim) s += cq_measure(d & 2);   /* re-joins; no break */
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
