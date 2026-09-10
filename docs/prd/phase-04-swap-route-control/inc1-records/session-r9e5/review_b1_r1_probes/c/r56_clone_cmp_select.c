#include "CQ.h"
__attribute__((noinline)) static int f(int q){ int r=cq_theta(7,0.5); return ((r>5)?2:5)+q; }
int main(void){ int q=cq_theta(3,0.2); return cq_measure(f(q)); }
