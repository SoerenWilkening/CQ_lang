#include "CQ.h"
/* §14: the measured name re-read a THIRD time, AFTER a rotation derived from it.
   Under the ruling `q` still denotes the definite basis state |m>, so this is legal. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(q,0.5);
  int m2=cq_measure(q); return m+m2+cq_measure(a); }
