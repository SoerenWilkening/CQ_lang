#include <stdio.h>
double g_d;
int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4);
  double ang = 0.1;
  if (q==5){ a = cq_theta(a,0.9); ang = 0.7; }
  cq_phi(ang);
  g_d = ang * 2.0;             /* a DATA use of the same peeled fp value */
  printf("%d %f\n", cq_measure(a), g_d); return 0;
}
