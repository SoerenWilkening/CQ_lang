#include "CQ.h"
static int slice(void) {
  int A=5,B=6,C=7,D=8;
  bool b = 0; b = cq_theta(b, 0.5);
  int q = 0; q = cq_theta(q, 0.7);
  if (b) { A-=3; B-=4; C-=5; D-=6; }
  q = cq_theta(q, 0.9);             /* trailing non-diagonal on a DISJOINT register */
  return cq_measure(A)+cq_measure(B)+cq_measure(C)+cq_measure(D)+cq_measure(b)+cq_measure(q);
}
int main(void){(void)slice();return 0;}
