#include "CQ.h"
/* CONTROL for r20: identical, but the arm theta reads the FRESH tip `a`
   (well-formed) — nothing should be recorded at all. */
int slice(int u){ int q=cq_theta(u,0.5); int a=cq_theta(q,0.3);
  bool f=cq_theta((bool)0,0.25); int r=a;
  if(f){ r=cq_theta(a,0.7); }
  return cq_measure(r); }
int main(void){ return slice(3); }
