#include "CQ.h"
/* leg 1 soundness: a NON-recursive helper called TWICE on the same tainted name. */
__attribute__((noinline)) static int f(int q){ int b=cq_theta(q,0.1); return cq_measure(b); }
int main(void){ int q=cq_theta(0,0.3); return f(q)+f(q); }
