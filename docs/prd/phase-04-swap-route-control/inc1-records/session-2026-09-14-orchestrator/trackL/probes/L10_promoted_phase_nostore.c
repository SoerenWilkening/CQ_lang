/* the PHASE-arm cascade, promoted, no store: W3 (the carried value arm) peeled away.
   Does the conditional in-loop prep (W2) stand alone? */
#include "CQ.h"
int main(void){ int a=5; int q=0; q=cq_theta(q,0.3);
  for(int i=0;i<3;++i){ bool t=0; if(q>3) t=cq_theta(t,0.5); if(t) cq_phi(0.5); }
  return cq_measure(q)+a; }
