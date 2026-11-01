#include "CQ.h"
/* cq-r8-d (190's escape, CR rule 27 Pointers): a void callee with no body handed a pointer into a local slot
 * object: the declared clone takes (object, tag, idx, cell count), the caller snapshots the cells, the twin
 * runs after the last read of a cell and before the clean-up of the rails the cells held. dp_reg: the
 * register alone (before this, the ORIGINAL ext_sink was called with the handle cells: a silent wrong call). */
extern void ext_sink(int *p, int n);
int dp_esc(int x0, double tx) {
    int x = x0;
    cq_theta(&x, tx);
    int a[2] = {x, x + 1};
    ext_sink(a, 2);
    return cq_measure(a[0]);
}
int dp_reg(int x0, double tx) {
    int x = x0;
    cq_theta(&x, tx);
    int a[1] = {x};
    ext_sink(a, 1);
    return 7;
}
int dp_after(int x0, double tx) {
    int x = x0;
    cq_theta(&x, tx);
    int a[2] = {x * 3, x - 1};
    ext_sink(a, 2);
    return cq_measure(a[1] + a[0]);
}
