/* tests/calls probe (cq-s2zz, CR rule 27 Results and Name, rules 25, 26): a declared clone with an aggregate
 * result (an i32 handle per scalar leaf, the twin undoing them together) and an aggregate argument (one digit
 * per field). Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec
 * declared_aggr.c -o declared_aggr.O1.ll */
#include "CQ.h"
typedef struct { double re, im; } cpx;
typedef struct { long a, b; } pr;
cpx ext_rot(double x, double y);
long ext_sum(pr p);
double da_res(double x0, double th, double y) {
    double x = x0;
    cq_theta(&x, th);
    cpx c = ext_rot(x, y);
    return cq_measure(c.re) + cq_measure(c.im);
}
long da_arg(long x0, double th, long b) {
    long x = x0;
    cq_theta(&x, th);
    pr p = {x, b};
    return cq_measure(ext_sum(p));
}
