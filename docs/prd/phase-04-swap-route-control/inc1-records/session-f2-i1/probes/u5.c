/* u5: compare-flag spelling -- CLAUDE.md says the ARM half arrives FOLDED. */
#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.25); _Bool c = (q == 5); _Bool r = c;
  if (c) r = cq_theta(c, 0.9);
  return cq_measure(q) + cq_measure(r); }
