#include "CQ.h"
/* cq-6b2i1: an observable volatile access at an address rail is rule 20's rail column. A local volatile array indexed
   by a rail is observable too: its pointer operand is not reached through untainted indices. */
volatile int vtab[4];
void p_vol_rail_store(int x0, double th, int v) {
    int i = x0 & 3;
    cq_theta(&i, th);
    vtab[i & 3] = v;
}
int p_vol_rail_load(int x0, double th) {
    int i = x0 & 3;
    cq_theta(&i, th);
    return cq_measure(vtab[i & 3] + i);
}
int p_vol_local_rail(int x0, double th, int v) {
    volatile int a[2];
    a[0] = v;
    a[1] = v + 1;
    int i = x0 & 1;
    cq_theta(&i, th);
    a[i & 1] = 9;
    return cq_measure(i) + a[0];
}
