#include "CQ.h"
__attribute__((noinline)) static int f(bool b){ return b?2:5; }
int main(void){ bool b=0,c=0; b=cq_theta(b,0.5); c=cq_theta(c,0.7); int a=f(b); int d=f(c); return cq_measure(a)+cq_measure(d)+cq_measure(b)+cq_measure(c); }
