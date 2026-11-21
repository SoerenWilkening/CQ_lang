// Rule 27 (owner ruling 2026-11-20): a listed function called with every actual classical. Nothing in this module stores
// a rail, so no cell can be QUANTUM: the call stays the C call of ext_sum (rule 16, an ordinary host call). The same
// call in declared_classical_mem.c, where a rail is stored, is the all-zero declared clone.
#include "CQ.h"
long ext_sum(const long *p, long n);
long A[4] = {1, 2, 3, 4};
long c(long a, long n) { long x = a; cq_theta(&x, 1.0); long s = ext_sum(A, n & 3); return cq_measure(x) + s; }
