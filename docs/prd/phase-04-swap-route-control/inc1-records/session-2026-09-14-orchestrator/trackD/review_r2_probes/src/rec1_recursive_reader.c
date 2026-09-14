#include "CQ.h"
/* leg 1 soundness: the reader is in a NON-cyclic CFG but the FUNCTION recurses, so the
   reader executes many times. Does an earlier owner claim the tainted call argument? */
__attribute__((noinline)) static int f(int q, int n){ if(n<=0) return 0;
  int b=cq_theta(q,0.1); return cq_measure(b)+f(q,n-1); }
int main(void){ int q=cq_theta(0,0.3); return f(q,3); }
