#include "CQ.h"
/* CLAUSE (C1) PROBE (bd 3d8q F-D2-2): the guard on the reader's block is a TAINTED
   compare, so "how many times does this block execute" has no classical answer —
   the arm runs in superposition. Leg 1b must refuse it at (C1), and the module must
   DECLINE on every binary. */
int main(void){ int q=cq_theta(0,0.3); int p=cq_theta(0,0.7); int s=0;
  for(int i=0;i<3;i++){ if(p==5){ int b=cq_theta(q,0.1); s+=cq_measure(b); } else s+=1; }
  return s; }
