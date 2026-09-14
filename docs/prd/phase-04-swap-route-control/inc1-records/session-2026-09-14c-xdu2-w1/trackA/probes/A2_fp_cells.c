/* Track A, clause C3 negative: DOUBLE cells. abiWidthFromType gives "f64", which
   widthHasReversibleCopy REFUSES (no cqrt_copy_f64) — the `.empty()` trap. */
#include "CQ.h"
int main(void){ double b[3]={0,0,0};
  for(int i=0;i<3;++i) b[i]=cq_theta(b[i],0.5);
  int s=0; for(int i=0;i<3;++i) s+=(int)cq_measure(b[i]); return s; }
