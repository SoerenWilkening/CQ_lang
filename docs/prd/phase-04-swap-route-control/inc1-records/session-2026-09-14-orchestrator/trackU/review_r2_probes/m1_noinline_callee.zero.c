/* lead 5 — the normalizer runs in EVERY function.  Here the theta with the undef
   seed lives in a noinline callee that main calls TWICE. */
#include "CQ.h"
__attribute__((noinline)) static int mk(double th) { int s = 0; return cq_theta(s, th); }
int main(void) { int p = mk(0.5); int q = mk(0.25); return cq_measure(p) + cq_measure(q); }
