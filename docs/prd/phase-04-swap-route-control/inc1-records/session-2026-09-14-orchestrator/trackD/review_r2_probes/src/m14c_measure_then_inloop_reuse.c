#include "CQ.h"
/* §14 ITEM 5 — THE INTERACTION. `q` is MEASURED before the loop, so under the ruling it
   denotes a definite, REPRODUCIBLE basis state and re-preparing it every trip is legal.
   The landed fence's ruled shape (loop-invariant re-read) is exactly this program. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int s=0;
  for(int i=0;i<3;i++){ int b=cq_theta(q,0.1); s+=cq_measure(b); } return s+m; }
