#include "CQ.h"
/* WELL-FORMED leg-2: the measure reads the loop-carried phi, the gate follows it in the
   SAME body, and the header phi re-establishes the record every trip. Must ACCEPT. */
int main(void){ int q=cq_theta(0,0.3); int s=0; for(int i=0;i<3;i++){ s+=cq_measure(q); q=cq_theta(q,0.1); } return s; }
