#include <stdio.h>
int main(void){
  int q = cq_theta(0,0.3);
  double ang = 0.1; int m = 5;
  if (q==5){ cq_phi(1.5); ang = 0.7; m = 7; }
  cq_phi(ang);
  printf("%d %d\n", cq_measure(q), cq_measure(m)); return 0;
}
