#include "CQ.h"
/* E2 adversarial: the undef measure's OUTCOME feeds a theta SEED (the allocator
   ABI's runtime-value slot). Does the refinement still hold once the rewritten
   value crosses into the quantum side as an alloc seed? */
int main(void){ int u; int m = cq_measure(u); int q = cq_theta(m, 0.3); return cq_measure(q); }
