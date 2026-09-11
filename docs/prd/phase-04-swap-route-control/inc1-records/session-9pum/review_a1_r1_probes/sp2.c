#include "CQ.h"
__attribute__((noinline)) int helper(int x) { if (x > 3) cq_phi(0.3); return 1; }
int main(void){ int q = cq_theta(0, 0.5); int m = cq_measure(q);
  return helper(q) + m; }
