#include "CQ.h"
/* E2 adversarial: the undef measure's OUTCOME is a CLASSICAL branch condition
   guarding quantum code. lowerMeasures runs AFTER control detection, so the
   region was never tainted; the rewrite must not manufacture one. */
int main(void){ int u; int m = cq_measure(u); int q = cq_theta(0, 0.3); if (m) q = cq_theta(q, 0.5); return cq_measure(q); }
