#include "CQ.h"
/* WELL-FORMED: two disjoint loops, each with its own in-body mint. */
int main(void){ int s=0;
  for(int i=0;i<3;i++){ int q=cq_theta(0,0.3); s+=cq_measure(cq_theta(q,0.1)); }
  for(int j=0;j<3;j++){ int r=cq_theta(0,0.4); s+=cq_measure(cq_theta(r,0.2)); }
  return s; }
