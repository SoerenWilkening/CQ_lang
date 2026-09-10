/* a16 — a loop with the rail RE-MINTED per trip, a CHAINED rail, and the
   measure naming the trip's PARENT (the closure question inside a loop). */
#include "CQ.h"
int main(void){ int acc=0; bool z=0;
  for(int i=0;i<3;i++){ bool p=cq_theta(z,0.5); bool b=cq_theta(p,0.3);
    int a=b?i:5; acc+=cq_measure(p)+cq_measure(a); }
  return acc; }
