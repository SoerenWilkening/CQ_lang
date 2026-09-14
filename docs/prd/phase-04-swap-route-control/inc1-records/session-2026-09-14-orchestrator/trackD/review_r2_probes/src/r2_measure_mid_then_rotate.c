#include "CQ.h"
/* WELL-FORMED: measure the tip, then extend the chain from the tip, then measure again. */
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.5); int m=cq_measure(a); int c=cq_theta(a,0.9); return m+cq_measure(c); }
