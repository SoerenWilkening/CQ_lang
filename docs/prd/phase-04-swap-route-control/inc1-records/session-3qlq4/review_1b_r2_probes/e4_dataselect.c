#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); int t=q&1; int b=cq_theta(t,0.5); int c=cq_theta(t,0.9); int r=(b==1)?7:9; return cq_measure(r)+cq_measure(c); }
