#include "CQ.h"
/* WELL-FORMED: the read is BEFORE the loop; the in-loop gate can never reach it (leg 1). */
int main(void){ int q=cq_theta(0,0.3); int s=cq_measure(q); for(int i=0;i<3;i++){ q=cq_theta(q,0.1); } return s+cq_measure(q); }
