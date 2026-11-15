// cq-bh7xh (owner ruling Q2; CR §1.4 "Received K", rule 27): a listed library function called from a defined callee
// reached by name from the table clone of k: the declared call's K is umin(@__cq_k, own K), loaded in the clone's entry
// block while that block is still being emitted.
#include "CQ.h"
double ext(double);
__attribute__((noinline)) static double g(double x) { return ext(x) * 2.0; }
double k(double a) { double x = a; cq_theta(&x, 1.0); double r = g(x); return cq_measure(r * r); }
