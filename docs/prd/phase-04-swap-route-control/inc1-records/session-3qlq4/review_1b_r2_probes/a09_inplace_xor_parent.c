#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); q ^= 5; int b=cq_theta(q,0.5); int c=cq_theta(q,0.9); if(b==1) cq_phi(0.7); return cq_measure(c); }
