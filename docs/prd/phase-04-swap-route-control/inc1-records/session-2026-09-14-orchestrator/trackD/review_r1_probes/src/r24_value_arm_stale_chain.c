#include "CQ.h"
/* STALE read inside a VALUE arm (emitValueRegion HOISTS the arm chain). */
int slice(int u){ int q=cq_theta(u,0.5); int a=cq_theta(q,0.3); int r=7;
  if(u==4){ r=q+1; }
  return cq_measure(a)+r; }
int main(void){ return slice(4); }
