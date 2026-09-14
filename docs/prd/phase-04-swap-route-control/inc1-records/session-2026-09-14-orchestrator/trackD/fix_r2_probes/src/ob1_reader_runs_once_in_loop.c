#include "CQ.h"
/* WELL-FORMED: the reader's BLOCK executes exactly once (i==0), so the loop-invariant
   `q` is read once and nothing is stale. The loop BODY runs 3 times, so the fixture's
   own retirement trigger ("the pass can prove a loop body executes at most once")
   does NOT cover this. Candidate OVER-DECLINE. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ if(i==0){ int b=cq_theta(q,0.1); s+=cq_measure(b); } else s+=1; }
  return s; }
