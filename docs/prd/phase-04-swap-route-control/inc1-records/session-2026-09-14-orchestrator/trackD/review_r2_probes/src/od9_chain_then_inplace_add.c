#include "CQ.h"
/* The GRANTING-direction risk named in WireWalk.h: the wire moves by an in-place add
   between the phi's latch incoming and the back edge. phiTracksWire counts only thetas. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ q=cq_theta(q,0.1); q=q+3; s+=cq_measure(q); } return s; }
