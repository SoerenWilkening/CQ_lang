/* h01 — a controlled I/O SINK (printf of a measured value) under a bare `_Bool`
   condition. `lowerControlledIOSinks` runs BEFORE detectControlRegions and mints
   its OWN flag — does it ask the rail ladder, or accept a rail? */
#include "CQ.h"
#include <stdio.h>
int main(void){ int q=0; q=cq_theta(q,0.2); bool b=0; b=cq_theta(b,0.5);
  if (b) printf("%d\n", cq_measure(q)); return 0; }
