#include "CQ.h"
int slice(int u){
  int q = cq_theta(u,0.5);
  bool y = (q>5) ? (bool)1 : (bool)0;
  bool b = cq_theta(y,0.5);
  bool c = cq_theta(y,0.9);
  if (b) cq_phi(0.7);
  return cq_measure(c)+cq_measure(q);
}
int main(void){ return slice(3); }
