#include "CQ.h"
static int slice(void) {
  int A=5,B=6,C=7,D=8;
  bool b = 0; b = cq_theta(b, 0.5);
  if (b) { A-=3; B-=4; C-=5; D-=6; }
  return cq_measure(A)+cq_measure(B)+cq_measure(C)+cq_measure(D);
}
int main(void){(void)slice();return 0;}
