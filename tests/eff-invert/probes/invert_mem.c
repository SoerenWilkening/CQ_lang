#include "CQ.h"
/* Rule 17, Memory: a bus store and an effect entry the backend performs at its call are flush points (performed in
   place and kept, only the gates after the last one reversed); an in-place form inverts exactly; a load un-copied
   inside the region reverses into itself. */
int cell;
__attribute__((noinline)) static void fill(int *p, int v) { *p = v; }
/* A kept bus store between two gates: the gate before it is flushed forward. */
int p_store_flush(int x0, double a, double b, int c) {
    int x = x0;
    int y = x0;
    cq_theta(&x, a);
    cq_invert_begin();
    cq_theta(&y, a);
    cell = x;
    cq_theta(&y, b);
    cq_invert_end();
    return cq_measure(y) + cell;
}
/* The in-place form on a cell (rule 5), inside the region: swap, gate, swap reversed. */
int p_inplace_cell(int x0, double a, double b, int c) {
    int m = x0;
    int *p = &m;
    fill(p, x0);
    cq_invert_begin();
    cq_theta(p, a);
    cq_theta(p, b);
    cq_invert_end();
    return cq_measure(*p);
}
/* A load whose copy is un-copied inside the region: its compute and un-copy reverse into themselves. */
int p_load_inside(int x0, double a, double b, int c) {
    int x = x0;
    cq_theta(&x, a);
    cell = x;
    int y = c;
    cq_theta(&y, b);
    cq_invert_begin();
    if (cell > c)
        cq_phi(b);
    cq_invert_end();
    return cq_measure(y);
}
/* An effect entry inside the region, a flush point too. */
extern void sinkfx(int);
int p_effect_flush(int x0, double a, double b) {
    int x = x0;
    cq_theta(&x, a);
    int y = x0;
    cq_invert_begin();
    cq_theta(&y, a);
    if (x > 2)
        sinkfx(x);
    cq_theta(&y, b);
    cq_invert_end();
    return cq_measure(y);
}
