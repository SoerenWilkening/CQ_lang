#include "CQ.h"
/* cq-05pa (CR rule 20, cq-e5lj): a global slot object read from outside a function that stores it: the module
   constructor seeds its cells with the initializer, every rail stored into it is kept, and a load with no
   dominating store reads the cell's current handle. */
static double gd = 1.5;
static int gi[3] = {7, 8, 9};
__attribute__((noinline)) static void put(double x) { gd = x * 3.0; }
__attribute__((noinline)) static double get(double y) { return gd + y; }
double global_outside_put_get(double a) { cq_theta(&a, 0.3); put(a); return cq_measure(get(a)); }
double global_outside_seed(double a) { cq_theta(&a, 0.3); return cq_measure(get(a)); }
__attribute__((noinline)) static void puti(int x, int k) { gi[k] = x ^ 5; }
__attribute__((noinline)) static int geti(int y, int k) { return gi[k] + y; }
int global_outside_index(int a, int k) {
    cq_theta(&a, 0.3);
    if (k < 0 || k > 2) return 0;
    puti(a, k);
    return cq_measure(geti(a, 2 - k));
}
