#include "CQ.h"
__attribute__((noinline)) int helper(int x) { int a = (x == 1) ? 2 : 5; return a; }
int main(void){ int q = cq_theta(0, 0.5); int m = cq_measure(q);
  return helper(q) + m; }
