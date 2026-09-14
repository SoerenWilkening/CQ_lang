#include "CQ.h"
/* WELL-FORMED leg-1 with a MEASURE reader: the two arms never both run. */
int main(void){ bool f=cq_theta((bool)0,0.5); int q=cq_theta(0,0.3); int r;
  if(f){ r=cq_theta(q,0.7); } else { r=cq_theta(q,0.2); } return cq_measure(r); }
