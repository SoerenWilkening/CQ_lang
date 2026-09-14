#include "CQ.h"
/* od1 with the two chains in the OTHER order — an order-dependent verdict would be a
   syntactic answer to a semantic question (L5). */
int main(void){ int q=cq_theta(0,0.3); int r=cq_theta(0,0.4); int s=0;
  for(int i=0;i<3;i++){ r=cq_theta(r,0.2); q=cq_theta(q,0.1); s+=cq_measure(q)+cq_measure(r); }
  return s; }
