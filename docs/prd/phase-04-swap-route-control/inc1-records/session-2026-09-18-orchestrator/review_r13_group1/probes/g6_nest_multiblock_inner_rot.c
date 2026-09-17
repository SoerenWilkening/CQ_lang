/* PART A — a NESTED loop whose INNER body is MULTI-BLOCK.  The inner rail is
   minted and read across two inner blocks.  markedHeaderOf is INNERMOST, so the
   inner body's key must be the INNER header; a discharge at the OUTER body's
   join would be K_inner adjoints against one forward gate. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i)
        for (int k = 1; k <= 3; ++k) {
            int d = (y >> (k + i));
            s += cq_measure(d & 1);
            if (k < lim) s += cq_measure(d & 2);
        }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
