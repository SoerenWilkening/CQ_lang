#include "CQ.h"
/* The shipped customer shape: a rolled Grover-style loop, chain + phase arm. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ q=cq_theta(q,0.2); if(q==5) cq_phi(3.14159); }
  s+=cq_measure(q); return s; }
