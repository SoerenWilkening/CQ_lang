#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5);
  for(int i=0;i<3;i++){ q=cq_theta(q,-0.5); if(q>5) cq_phi(3.14159); }
  return cq_measure(q); }
int main(void){ return slice(3); }
