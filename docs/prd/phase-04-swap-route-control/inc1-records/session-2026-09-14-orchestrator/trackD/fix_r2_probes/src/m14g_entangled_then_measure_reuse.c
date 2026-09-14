#include "CQ.h"
/* §14 ITEM 2: the ENTANGLED case. `g` is rotated under quantum control of `q`, so the two
   are correlated; then `q` is measured and re-used. Chain-vs-fresh-alloc question. */
int main(void){ int q=cq_theta(0,0.3); int g=cq_theta(0,0.2);
  if(q==1) g=cq_theta(g,0.7);
  int m=cq_measure(q); int a=cq_theta(q,0.5); return m+cq_measure(a)+cq_measure(g); }
