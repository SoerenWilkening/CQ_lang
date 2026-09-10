#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); int t=q&1; int b=cq_theta(t,0.5); int c=cq_theta(t,0.9); if(b==1){ cq_phi(0.2); if(q>5) cq_phi(0.7);} return cq_measure(c); }
