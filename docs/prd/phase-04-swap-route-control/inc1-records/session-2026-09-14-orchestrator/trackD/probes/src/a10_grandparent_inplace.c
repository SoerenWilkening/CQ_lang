#include "CQ.h"
/* sibling theta on the PRE-xor name q; the xor is in-place so both rails are one */
int main(void){ int q=cq_theta(0,0.3); int x=q^5; int b=cq_theta(x,0.5); int c=cq_theta(q,0.9); if(b==1) cq_phi(0.7); return cq_measure(c); }
