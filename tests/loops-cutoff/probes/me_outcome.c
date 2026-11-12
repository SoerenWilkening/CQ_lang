/* tests/loops-cutoff probe (rulings Q3, 2026-11-11; CR rules 2, 8): a cq_measure behind a classical branch on an
   earlier measurement's outcome. m is collapsed statically (measured on every path), so (m & 1) is a classical
   condition: the second register's first measurement runs only where m is odd, and y stays coherent on the other path.
   run_probes.py MUTANTS: that measurement hoisted above the branch on (m & 1) is rejected.
   Regenerate me_outcome.O1.ll:
   clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec me_outcome.c -o me_outcome.O1.ll */
#include "CQ.h"
int meas_behind_outcome(int x0, int y0, double th) {
    int x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
    int m = cq_measure(x);
    if (m & 1) return cq_measure(y);
    cq_theta(&y, -th);
    return m + cq_measure(y);
}
