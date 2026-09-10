#include "CQ.h"
int main(void){
  bool b = cq_theta((bool)0, 0.5);
  for (int i = 0; i < 2; ++i) {
    if (b) cq_phi(3.14159265358979);      /* oracle: phase the |1> branch */
    b = cq_theta(b, 0.9);                 /* diffusion */
    if (!b) cq_phi(3.14159265358979);     /* reflection about |0> */
    b = cq_theta(b, -0.9);
  }
  return cq_measure(b);
}
