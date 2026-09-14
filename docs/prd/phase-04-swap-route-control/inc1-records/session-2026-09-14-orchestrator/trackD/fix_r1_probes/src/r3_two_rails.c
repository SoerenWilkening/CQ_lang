#include "CQ.h"
/* WELL-FORMED: two INDEPENDENT rails, one chain each. Must ACCEPT. */
int main(void){ int q1=cq_theta(0,0.3); int q2=cq_theta(1,0.4); int a=cq_theta(q1,0.5); int b=cq_theta(q2,0.6); return cq_measure(a)+cq_measure(b); }
