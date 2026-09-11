/* mp: TWO merge phis under an int compare -- isolates the multi-phi decline (b6ap). */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.25); int r = 7; int s = 9;
  if (q > 5) { r = cq_theta(7, 0.5); s = cq_theta(9, 0.5); }
  return cq_measure(q)+cq_measure(r)+cq_measure(s); }
