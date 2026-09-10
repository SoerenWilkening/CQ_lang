#include "CQ.h"
__attribute__((noinline)) static int g(bool b){ if (b) cq_phi(0.7); return 0; }
int main(void){ bool b = cq_theta((bool)0,0.5); int r = g(b); return r + cq_measure(b); }
