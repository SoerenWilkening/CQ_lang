/* a12 — the same, but the rail is LOOP-INVARIANT (minted before the loop).
   Expect DECLINE at rung (iii) (the back edge defeats the DT prong). */
#include "CQ.h"
int main(void){ int acc=0; bool z=0; bool b=cq_theta(z,0.5);
  for(int i=0;i<3;i++){ int a=b?i:5; bool c=cq_theta(b,0.3);
    acc+=cq_measure(c)+cq_measure(a); }
  return acc; }
