#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5); int q2 = cq_theta(q, 0.3);
  int m = cq_measure(q);                  /* names the PARENT of q2's wire */
  int a = (q2 == 1) ? 2 : 5; return m + a; }
