#include "CQ.h"
static const int T[4] = {3,5,9,1};
int slice(int u){
  int q = cq_theta(u,0.5);
  int y = T[q & 3];               /* QROM read -> tainted at QramLowering */
  int b = cq_theta(y,0.5); int c = cq_theta(y,0.9);
  if (b == 1) cq_phi(0.7);
  return cq_measure(c)+cq_measure(q);
}
int main(void){ return slice(3); }
