#include "CQ.h"
__attribute__((noinline)) static int f(bool b){ return b?2:5; }
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=f(b); return cq_measure(a)+cq_measure(b); }
