/* Track A, clause C2 — the AXIS fixture in its strongest form: a TAINTED index
   INSIDE a classically-bounded loop, i.e. both of the rail bank's own structural
   conditions present and only the index axis different. Must keep 7.5's string. */
#include "CQ.h"
int main(void){ int q=cq_theta(0,0.5); bool b[4]={0};
  for(int i=0;i<4;++i) b[(q+i)&3]=cq_theta(b[(q+i)&3],0.5);
  return cq_measure(b[0]); }
