#include "CQ.h"
volatile int v=1;
int main(void){ bool b=cq_theta((bool)0,0.5); int r=0;
  if(v){ if(b) cq_phi(0.7); } else { r = cq_measure(b); }   /* the measure arm cannot reach the branch */
  return r; }
