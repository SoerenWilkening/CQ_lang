#include "CQ.h"
int main(void){ long long q=cq_theta(0LL,0.3); int t=(int)q; int b=cq_theta(t,0.5); int c=cq_theta(t,0.9); if(b==1) cq_phi(0.7); return cq_measure(c); }
