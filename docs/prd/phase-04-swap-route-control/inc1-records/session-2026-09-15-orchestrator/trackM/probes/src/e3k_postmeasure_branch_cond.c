#include "CQ.h"
/* E3 CONTROL P4: the measured name read as a tainted BRANCH CONDITION after the
   measure. Under (b) the condition is CLASSICAL, so the cq_phi is an UNCONTROLLED
   global phase and is DELETED (Rule 3). Today the condition is quantum. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q);
  if (q == 5) cq_phi(0.3);
  return m; }
