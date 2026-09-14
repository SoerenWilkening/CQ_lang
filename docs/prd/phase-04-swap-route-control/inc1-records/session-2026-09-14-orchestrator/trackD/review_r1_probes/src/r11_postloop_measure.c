#include "CQ.h"
/* WELL-FORMED leg-2: the post-loop measure reads the exit value of a self-assigned chain. */
int main(void){ int q=cq_theta(0,0.3); for(int i=0;i<4;i++){ q=cq_theta(q,0.1); } return cq_measure(q); }
