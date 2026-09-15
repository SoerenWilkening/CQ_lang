#include "CQ.h"
/* E2 adversarial: a CLASSICAL undef measure sitting INSIDE a tainted-condition
   arm. Control lowering and RegionFlatten run before lowerMeasures, so the call
   is wherever the flatten left it. */
int main(void){ int u; int q = cq_theta(0, 0.3); int a = 1; if (q == 3) { a = cq_measure(u) + 2; } return cq_measure(q) + a; }
