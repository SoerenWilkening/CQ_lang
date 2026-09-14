#include "CQ.h"
/* THE DISCRIMINATING ACCEPT (f1w2): one chain, the TIP measured twice. */
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.5); int c=cq_theta(a,0.9); return cq_measure(c)+cq_measure(c); }
