#include "CQ.h"
/* The bd z9t1 spelling: an UNINITIALIZED seed, ruled 2026-09-14 to compile silently.
   The header phi's pre-loop incoming is undef/poison -> a non-Instruction. */
int main(void){ int q; int s=0; for(int i=0;i<3;i++){ q=cq_theta(q,0.1); s+=cq_measure(q); } return s; }
