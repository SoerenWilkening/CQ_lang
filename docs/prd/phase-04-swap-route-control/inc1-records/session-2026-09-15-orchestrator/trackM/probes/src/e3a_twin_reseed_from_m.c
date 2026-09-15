#include "CQ.h"
/* E3 TWIN of m14a: the post-measure re-use spelled EXPLICITLY as a re-seed from the
   measurement outcome — i.e. exactly what reading (b) rewrites m14a into. If this
   compiles on the ORACLE, E3's target stream is READ OFF THE SHIPPED COMPILER and
   the increment is an ACCEPT-only widening onto an already-cleared stream. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(m,0.5); return m+cq_measure(a); }
