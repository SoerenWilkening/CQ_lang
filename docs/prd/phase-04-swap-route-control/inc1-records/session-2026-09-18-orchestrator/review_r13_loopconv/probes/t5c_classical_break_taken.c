/* SUBJECT (C) ATTACK — THE WITNESS bd tu9q.1 SAYS DOES NOT EXIST.
   `r1_break_loop`'s break condition is `s > 1`, and `s` is a sum of
   `cq_measure` results, which the TRACE RUNTIME ALWAYS RETURNS 0 FOR — so the
   shipped witness runs the NON-BREAK path only.  Here the break predicate is
   CLASSICAL (`lim` comes from `argc`, opaque at compile time), so the runtime
   TAKES IT at k == 2.  Reference = `t5c_ref_two_trips.c`, the straight-line
   program this loop DENOTES when lim == 2. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        s += cq_measure((y >> k) & 1);
        if (k >= lim) break;               /* CLASSICAL — taken at k == 2 */
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
