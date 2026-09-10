#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); int t1=q&1; int t2=q&2; int b=cq_theta(t1,0.5); int c=cq_theta(t2,0.9); if(b==1) cq_phi(0.7); return cq_measure(c); }
