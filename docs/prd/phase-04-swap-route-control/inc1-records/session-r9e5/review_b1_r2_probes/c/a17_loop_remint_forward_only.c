/* a17 — a loop, rail re-minted per trip, a FORWARD theta AFTER the select and
   nothing measured on it: the leg-2 barrier accept in its purest form. */
#include "CQ.h"
int main(void){ int acc=0; bool z=0;
  for(int i=0;i<3;i++){ bool b=cq_theta(z,0.5); int a=b?i:5;
    bool c=cq_theta(b,0.3); (void)c; acc+=cq_measure(a); }
  return acc; }
