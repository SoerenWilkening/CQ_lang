#include "CQ.h"
int slice(int u){
  int q = cq_theta(u,0.5);
  for (int i=0;i<3;i++) q = cq_theta(q,0.1);
  int b = cq_theta(q,0.5); int c = cq_theta(q,0.9);
  if (b == 1) cq_phi(0.7);
  return cq_measure(c);
}
int main(void){ return slice(3); }
