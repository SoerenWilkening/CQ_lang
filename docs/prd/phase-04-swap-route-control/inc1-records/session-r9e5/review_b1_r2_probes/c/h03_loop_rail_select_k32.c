/* h03 — a rail-conditioned select inside a classically bounded loop, K = 32.
   Per-activation alloc/free accounting (stage 2b is blind to a leaked ancilla). */
#include "CQ.h"
int main(void){ int acc=0; bool z=0;
  for(int i=0;i<32;i++){ bool b=cq_theta(z,0.5); int a=b?i:5; acc+=cq_measure(a); }
  return acc; }
