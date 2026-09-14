#include "CQ.h"
/* DELTA-SCOPE attack, the ROUTING sub-case the implementer's structural argument
   does not cover: the staler `s` hangs off a ROUTING node `Z` that is tainted at
   ROUND 1 (via `w`), so `s` is NOT in the round-2 delta, while the reader
   `cq_measure(rec)` is not in it either. No compare on the rail. */
int ext_f(int a);
int slice(int u){
  int q = cq_theta(0, 0.5);
  int y = 5; if (q > 5) y = ext_f(7);
  int w = cq_theta(1, 0.4);
  int Z = u ? y : w;
  int rec = cq_theta(y, 0.25);
  int s   = cq_theta(Z, 0.6);
  return cq_measure(rec) + cq_measure(s) + cq_measure(q);
}
int main(void){ return slice(1); }
