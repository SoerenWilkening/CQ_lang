/* a11 — the forward name in a LOOP whose rail is RE-MINTED each trip (so the
   seed's own def is a barrier and gateIsHarmless' leg 2 can accept). The
   measure of the forward name then reaches the NEXT trip's select. */
#include "CQ.h"
int main(void){ int acc=0; bool z=0;
  for(int i=0;i<3;i++){ bool b=cq_theta(z,0.5); int a=b?i:5;
    bool c=cq_theta(b,0.3); acc+=cq_measure(c)+cq_measure(a); }
  return acc; }
