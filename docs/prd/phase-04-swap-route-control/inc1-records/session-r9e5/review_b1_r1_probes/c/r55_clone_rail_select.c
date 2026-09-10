#include "CQ.h"
__attribute__((noinline)) static int f(int q){ bool b=0; b=cq_theta(b,0.5); return (b?2:5)+q; }
int main(void){ int q=cq_theta(3,0.2); return cq_measure(f(q)); }
