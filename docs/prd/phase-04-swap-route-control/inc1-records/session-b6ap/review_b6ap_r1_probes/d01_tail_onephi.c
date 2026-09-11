#include <stdio.h>
int main(void){
  int q = cq_theta(0,0.3);
  double ang = 0.1;
  if (q==5){ cq_phi(1.5); ang = 0.7; }
  cq_phi(ang);
  printf("%d\n", cq_measure(q)); return 0;
}
