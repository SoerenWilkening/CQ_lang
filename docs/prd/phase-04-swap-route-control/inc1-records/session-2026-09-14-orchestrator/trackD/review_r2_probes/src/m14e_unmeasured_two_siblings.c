#include "CQ.h"
/* THE CONTROL for m14d: identical but with NO measurement. Must stay a DECLINE — this is
   bd 3d8q's headline program. The pair isolates "does the measurement change the verdict?" */
int main(void){ int q=cq_theta(0,0.3);
  int b=cq_theta(q,0.5); int c=cq_theta(q,0.9); return cq_measure(b)+cq_measure(c); }
