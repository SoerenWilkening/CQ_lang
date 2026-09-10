#include "CQ.h"
__attribute__((pure)) int pf(int x);
int main(void){ int q=cq_theta(3,0.2); int q2=cq_theta(4,0.5); int t=5; if(q>5){ t=pf(7);} int u=t+1; int a=(q2>5)?u:9; return cq_measure(a)+cq_measure(q2)+cq_measure(q); }
