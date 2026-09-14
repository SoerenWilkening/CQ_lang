#include "CQ.h"
/* The controlled STATE PREP whose SEED name was already consumed. */
int slice(int u){ int q=cq_theta(u,0.5); int a=cq_theta(q,0.3);
  bool f=cq_theta((bool)0,0.25); int r=q;
  if(f){ r=cq_theta(5,0.7); }
  return cq_measure(a)+cq_measure(r); }
int main(void){ return slice(3); }
