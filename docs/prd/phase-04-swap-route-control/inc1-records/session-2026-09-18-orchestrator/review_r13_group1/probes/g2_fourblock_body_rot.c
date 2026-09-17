/* PART A — a FOUR-block marked body (two sequential re-joining classical ifs).
   Same obligation as g1 at one more level of split. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k < lim)   s += cq_measure(d & 2);
        if (k > lim-2) s += cq_measure(d & 4);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
