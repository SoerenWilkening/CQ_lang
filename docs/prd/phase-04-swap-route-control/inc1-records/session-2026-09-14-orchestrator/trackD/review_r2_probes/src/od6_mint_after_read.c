#include "CQ.h"
/* WELL-FORMED: the reader reads the PREVIOUS trip's fresh mint. The record is a header
   phi over {entry mint, body mint}; both incomings are thetas that end their blocks. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int b=cq_theta(q,0.1); s+=cq_measure(b); q=cq_theta(0,0.4); } return s; }
