#include "CQ.h"
/* THE DEVIATION under adjudication: cq_measure(q) AFTER a=cq_theta(q,.5) consumed q. */
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.5); return cq_measure(q)+a; }
