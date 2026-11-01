#include "CQ.h"
/* cq-r8-d: a cell holding a classical value at a declared clone call (rule 27 object digit): unimplemented. */
extern void ext_sink(int *p, int n);
int dp_classical_cell(int x0, double tx, int k) {
    int x = x0;
    cq_theta(&x, tx);
    int a[2] = {x * 3, k};
    ext_sink(a, 2);
    return cq_measure(a[0]);
}
