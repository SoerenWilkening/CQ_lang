#include "CQ.h"
/* WELL-FORMED: the mint is in the body header, the reader in a guarded inner block. */
int main(void){ int s=0; for(int i=0;i<4;i++){ int q=cq_theta(0,0.3);
  if(i&1){ int b=cq_theta(q,0.1); s+=cq_measure(b); } } return s; }
