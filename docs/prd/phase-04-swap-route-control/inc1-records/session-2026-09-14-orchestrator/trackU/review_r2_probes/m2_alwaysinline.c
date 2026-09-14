#include "CQ.h"
__attribute__((always_inline)) static inline int mk(double th) { int s; return cq_theta(s, th); }
int main(void) { int p = mk(0.5); int q = mk(0.25); return cq_measure(p) + cq_measure(q); }
