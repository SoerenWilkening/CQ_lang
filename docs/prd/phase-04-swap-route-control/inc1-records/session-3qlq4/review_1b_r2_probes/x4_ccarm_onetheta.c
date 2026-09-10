#include "CQ.h"
int ext_f(int a);
int slice(int u){
  int q = cq_theta(u,0.5);
  int y = 5;
  if (q > 5) y = ext_f(7);
  int b = cq_theta(y,0.5);
  if (b == 1) cq_phi(0.7);
  return cq_measure(b)+cq_measure(q);
}
