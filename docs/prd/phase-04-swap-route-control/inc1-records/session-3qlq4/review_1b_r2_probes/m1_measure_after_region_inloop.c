#include "CQ.h"
int slice(int u){ int acc=0; bool b=cq_theta((bool)(u&1),0.5);
  for(int i=0;i<3;i++){ if(b) cq_phi(0.7); acc += cq_measure(b); }
  return acc; }
int main(void){ return slice(3); }
