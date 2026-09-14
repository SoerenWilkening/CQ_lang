#include "CQ.h"
/* WELL-FORMED: a chain whose parent is a TEMPLATE-minted rail. Must ACCEPT. */
int main(void){ int q=cq_theta(0,0.3); int t=q+1; int a=cq_theta(t,0.5); return cq_measure(a); }
