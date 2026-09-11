#include <stdio.h>
int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4);
  double ang = 0.1;
  if (q==5){ a = cq_theta(a,0.9); ang = 0.7; }
  cq_phi(ang);
  printf("%d\n", cq_measure(a)); return 0;
}
