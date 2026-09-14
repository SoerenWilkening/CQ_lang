#include "CQ.h"
/* WELL-FORMED: the chain's seed is the CLASSICAL literal 0, so the header phi has a
   CONSTANT incoming. Trip 1 mints, trips 2-3 chain. phiTracksWire refuses any
   non-Instruction incoming -> candidate over-DECLINE. */
int main(void){ int q=0; int s=0; for(int i=0;i<3;i++){ q=cq_theta(q,0.1); s+=cq_measure(q); } return s; }
