#include "CQ.h"
/* Three independent chains — widen od1. */
int main(void){ int q=cq_theta(0,0.3); int r=cq_theta(0,0.4); int t=cq_theta(0,0.5); int s=0;
  for(int i=0;i<3;i++){ q=cq_theta(q,0.1); r=cq_theta(r,0.2); t=cq_theta(t,0.15);
    s+=cq_measure(q)+cq_measure(r)+cq_measure(t); } return s; }
