#include "CQ.h"
static int slice(void) {
  int A=5,B=6,C=7,D=8;
  int q = 0; q = cq_theta(q, 0.5);
  bool c = (q > 1);
  bool n = !c;
  if (n) { A-=3; B-=4; C-=5; D-=6; }
  return cq_measure(A)+cq_measure(B)+cq_measure(C)+cq_measure(D)
       + cq_measure(c) + cq_measure(n) + cq_measure(q);
}
int main(void){(void)slice();return 0;}
