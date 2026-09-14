#include "CQ.h"
/* WELL-FORMED: nested loops, the mint is in the INNER body beside the reader. */
int main(void){ int s=0; for(int i=0;i<2;i++){ for(int j=0;j<2;j++){
  int q=cq_theta(0,0.3); s+=cq_measure(cq_theta(q,0.1)); } } return s; }
