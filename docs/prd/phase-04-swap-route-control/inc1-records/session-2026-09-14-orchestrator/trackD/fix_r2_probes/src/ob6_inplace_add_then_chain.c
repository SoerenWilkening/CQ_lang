#include "CQ.h"
/* WELL-FORMED: the loop-carried rail moves by an in-place add and is then rotated. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ q=q+1; q=cq_theta(q,0.1); s+=cq_measure(q); } return s; }
