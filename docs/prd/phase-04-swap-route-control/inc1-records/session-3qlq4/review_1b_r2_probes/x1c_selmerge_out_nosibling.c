#include "CQ.h"
int slice(int u){
  int q = cq_theta(u,0.5);
  int y = (q>5) ? 3 : 7;
  int b = cq_theta(y,0.5);
  if (b == 1) cq_phi(0.7);
  return cq_measure(b)+cq_measure(q);
}
int main(void){ return slice(3); }
