#include "CQ.h"
/* STALE: `a` consumes `q`; the arm's theta then reads the stale `q`.
   The arm theta is an in-place-Ry arm — the emitter ERASES it between the
   EARLY record and the LATE drain, which NULLS the WeakTrackingVH. */
int slice(int u){ int q=cq_theta(u,0.5); int a=cq_theta(q,0.3);
  bool f=cq_theta((bool)0,0.25); int r=q;
  if(f){ r=cq_theta(q,0.7); }
  return cq_measure(a)+cq_measure(r); }
int main(void){ return slice(3); }
