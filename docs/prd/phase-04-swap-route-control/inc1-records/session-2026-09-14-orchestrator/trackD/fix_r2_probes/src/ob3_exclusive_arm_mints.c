#include "CQ.h"
/* WELL-FORMED: both arms mint their own seed and read it in the same arm. */
int main(void){ int s=0;
  for(int i=0;i<4;i++){ if(i&1){ int q=cq_theta(0,0.3); s+=cq_measure(cq_theta(q,0.1)); }
                        else   { int r=cq_theta(0,0.4); s+=cq_measure(cq_theta(r,0.2)); } }
  return s; }
