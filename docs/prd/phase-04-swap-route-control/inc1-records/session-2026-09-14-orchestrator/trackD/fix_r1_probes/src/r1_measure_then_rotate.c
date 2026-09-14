#include "CQ.h"
/* WELL-FORMED: the read of q happens BEFORE the gate that consumes it. Must ACCEPT. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(q,0.5); return m+cq_measure(a); }
