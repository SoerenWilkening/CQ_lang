#include "CQ.h"
__attribute__((pure)) int pf(int x);
int main(void){ int q=cq_theta(3,0.2); bool b=0; b=cq_theta(b,0.5); int t=5; if(q>5){ t=pf(7);} int u=t+1; int a=b?u:9; return cq_measure(a)+cq_measure(b)+cq_measure(q); }
