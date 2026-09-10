#include "CQ.h"
int slice(int u){
  int q = cq_theta(u,0.5); int y;
  switch(q & 3){ case 0: y=3; break; case 1: y=5; break; case 2: y=9; break; default: y=1; }
  int b = cq_theta(y,0.5); int c = cq_theta(y,0.9);
  if (b == 1) cq_phi(0.7);
  return cq_measure(c)+cq_measure(q);
}
int main(void){ return slice(3); }
