#include "CQ.h"
/* WELL-FORMED: the seed is minted in the body (barrier on every back-edge path) and the
   loop has TWO back edges because of the `continue`. */
int main(void){ int s=0; for(int i=0;i<4;i++){ int q=cq_theta(0,0.3); if(i&1){ s+=1; continue; }
  int b=cq_theta(q,0.1); s+=cq_measure(b); } return s; }
