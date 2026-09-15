#include "CQ.h"
/* E3 POSITION P3 — the brief's back-edge question, verbatim: `for(...) s += cq_measure(q);`
   `q` has NO use other than the measure's own operand, which E3 excludes by construction,
   so the module is UNCHANGED. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ s+=cq_measure(q); } return s; }
