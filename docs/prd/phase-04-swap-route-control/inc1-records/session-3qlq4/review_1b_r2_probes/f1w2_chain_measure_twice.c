#include "CQ.h"
/* WELL-FORMED: one chain, the final name measured twice (measuring twice is legal, it is the same register) */
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.5); int c=cq_theta(a,0.9); return cq_measure(c)+cq_measure(c); }
