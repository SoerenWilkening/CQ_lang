// Rule 27 (owner ruling 2026-11-20): as declared_classical.c, but a rail is stored into A first: a cell can be QUANTUM at
// the call, so the all-classical call is the declared clone of the all-zero arrangement, the pointer and n as C values.
#include "CQ.h"
long ext_sum(const long *p, long n);
long A[4] = {1, 2, 3, 4};
long cm(long a, long n) { long x = a; cq_theta(&x, 1.0); A[1] = x; long s = ext_sum(A, n & 3); return cq_measure(s); }
