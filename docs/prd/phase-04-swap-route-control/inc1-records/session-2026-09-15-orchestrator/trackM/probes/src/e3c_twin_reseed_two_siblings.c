#include "CQ.h"
/* E3 TWIN of m14d (two siblings off a measured name) -> two INDEPENDENT rails each
   seeded |m>. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(m,0.5); int b=cq_theta(m,0.9); return m+cq_measure(a)+cq_measure(b); }
