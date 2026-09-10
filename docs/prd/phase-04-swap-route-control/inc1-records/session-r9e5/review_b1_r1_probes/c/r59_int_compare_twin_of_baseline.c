/* the int/compare twin of the owner's program (the shipped reduction claim) */
#include "CQ.h"
int main(void){ int a=5; int b0=0; if(a>=3) b0=cq_theta(b0,0.5); if(b0==1) a-=3; return cq_measure(b0)+cq_measure(a); }
