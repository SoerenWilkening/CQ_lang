/* h06 — a chain that BORROWS the register (z = b + 1) beside the select, both
   measured: the whole-DAG spine's disposition of h_b with two cnot users. */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; int z=(int)b+1;
  return cq_measure(a)+cq_measure(z); }
