/* R2 lead 1b: a CHAINED theta on a normalized rail, then cq_invert.
   The chained theta's arg-0 is an SSA handle (never normalized); only the
   SOURCE seed moves. Does the adjoint/escape walk see a different rail? */
#include "CQ.h"
int cq_invert_i32(int);
int main(void) {
    int s;
    int q  = cq_theta(s, 0.5);
    int q2 = cq_theta(q, 0.25);
    return cq_invert_i32(q2);
}
