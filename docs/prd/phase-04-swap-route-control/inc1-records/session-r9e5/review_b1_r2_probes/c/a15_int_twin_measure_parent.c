/* a15 — THE COMPARE TWIN of a02 (int register). The compare classifier has no
   measured-before rung at all (bd r10v), so this ACCEPTS on both binaries; it is
   the discriminator that says the fix is rail-side only. */
#include "CQ.h"
int main(void){ int q=0; q=cq_theta(q,0.5); int b=cq_theta(q,0.3);
  int m=cq_measure(q); int a=(b==1)?2:5; return m+cq_measure(a); }
