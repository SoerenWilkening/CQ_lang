#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5);
  for(int i=0;i<4;i++){ if((q>>i)&1) cq_phi(0.7); }
  return cq_measure(q); }
int main(void){ return slice(3); }
