#include "CQ.h"
__attribute__((noinline)) static int f(int q){ bool b = cq_theta((bool)0,0.5); if (!b) cq_phi(0.7); return q + 1; }
int main(void){ int q = cq_theta(0,0.3); q = f(q); return cq_measure(q); }
