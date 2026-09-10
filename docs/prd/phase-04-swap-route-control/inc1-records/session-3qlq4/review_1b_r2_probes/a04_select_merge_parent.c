#include "CQ.h"
volatile int v=1;
int main(void){ int q=cq_theta(0,0.3); int m = (q>5) ? (q+1) : (q+2); int b=cq_theta(m,0.5); int c=cq_theta(m,0.9); if(b==1) cq_phi(0.7); return cq_measure(c); }
