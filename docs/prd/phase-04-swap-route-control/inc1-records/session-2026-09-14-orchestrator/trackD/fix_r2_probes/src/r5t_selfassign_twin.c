#include "CQ.h"
/* THE WELL-FORMED TWIN of r5: the self-assigned chain. A DIFFERENT program. */
int main(void){ int q=cq_theta(0,0.3); int s=0; for(int i=0;i<3;i++){ q=cq_theta(q,0.1); s+=cq_measure(q); } return s; }
