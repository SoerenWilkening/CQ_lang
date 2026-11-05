#include "CQ.h"
/* Rule 5's in-place form over its class, against the C program (cqcheck user). */
int g1 = 11, g2 = 22, g3[2] = {3, 4};
_Bool b1 = 1, b2 = 0;
double dcell = 1.5;
unsigned short hw = 0x1234;

/* `*p += *q`: the operand a plain load at its program point; q == p reaches the same cell. */
__attribute__((noinline)) static void add_cells(int *p, int *q) { *p += *q; }
int f_add_cells(int x0, double th, int same) {
    int x = x0;
    cq_theta(&x, th);
    g3[0] = x;
    add_cells(&g3[0], same ? &g3[0] : &g3[1]);
    return cq_measure(g3[0]) + g3[1];
}
/* Another reader of y: a plain load before the swap-out. */
int f_old(int d, double th) {
    cq_theta(&g1, th);
    int old = g1;
    g1 = old + d;
    return cq_measure(old) * 1000 + cq_measure(g1);
}
/* Later readers of y': one load after the swap-in, also as a kept store's value. */
int f_new(int d, double th) {
    cq_theta(&g2, th);
    int v = g2 ^ d;
    g2 = v;
    g3[1] = v;
    return cq_measure(v + 1);
}
/* A chain of bijections with a rotation in the middle. */
int f_chain(int k, double th) {
    int y = g1;
    y ^= k;
    y = y * 3;
    cq_theta(&y, th);
    y = 5 - y;
    y = ~y;
    y = __builtin_bswap32(y);
    y = (y << 7) | ((unsigned)y >> 25);
    g1 = y;
    return cq_measure(g1);
}
/* A value at a cq_theta step with another reader ends its form. */
int f_ends(int d, double th) {
    int y = g2;
    cq_theta(&y, th);
    int r = y;
    g2 = y + d;
    return cq_measure(r) * 3 + cq_measure(g2);
}
/* Under a quantum predicate: the composite, the controlled gate. */
int f_under(int x0, double tx, double th, int d) {
    int x = x0;
    cq_theta(&x, tx);
    if (x > 2) {
        g1 += d;
        cq_theta(&g2, th);
    }
    return cq_measure(g1) + cq_measure(g2) * 2 + cq_measure(x) * 4;
}
/* A select step: its arms updates of y or y itself, its condition not reading y. */
int f_select(int x0, double tx, int c, int d) {
    int x = x0;
    cq_theta(&x, tx);
    int y = g1;
    int z = x > 2 ? y + d : y;
    g1 = z;
    int y2 = g2;
    g2 = c ? y2 + 1 : y2 - 1;
    return cq_measure(g1) + cq_measure(g2) + cq_measure(x);
}
/* _Bool cells: the form at i1, the load at i1. */
int f_bool(double t1, double t2) {
    cq_theta(&b1, t1);
    cq_theta(&b2, t2);
    b1 ^= b2;
    b2 = !b2;
    return cq_measure(b1) + cq_measure(b2) * 2;
}
/* fneg and a narrow cell. */
double f_fneg(double th) {
    dcell = -dcell;
    cq_theta(&hw, th);
    hw ^= 5;
    return cq_measure(dcell) + cq_measure(hw);
}
/* A rail's kept store forwarded, a change between, through pointers. */
__attribute__((noinline)) static int fwd(int *restrict p, int *restrict q, int v, double t) {
    *p = v;
    *q = v + 1;
    cq_theta(p, t);
    return cq_measure(*p);
}
int f_fwd(int x0, double tx, double t) {
    int x = x0;
    cq_theta(&x, tx);
    return fwd(&g3[0], &g3[1], x, t) + cq_measure(g3[0]) + cq_measure(g3[1]);
}
