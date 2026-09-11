#include <stdio.h>
volatile double rv = 0.7;
int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4);
  double t = rv;
  double ang = 0.1;
  if (q==5){ a = cq_theta(a,0.9); ang = t; }
  cq_phi(ang);                 /* Rz stem, RUN-TIME arm */
  printf("%d\n", cq_measure(a)); return 0;
}
