#include "CQ.h"
/* §14: a PURE op on a measured name — declineStaleRecordOps' half of the same question. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(q,0.5);
  int d=q+1; return m+d+cq_measure(a); }
