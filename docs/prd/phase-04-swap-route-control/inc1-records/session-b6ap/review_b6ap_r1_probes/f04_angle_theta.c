#include <stdio.h>
int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4), b=cq_theta(0,0.2);
  double ang = 0.1;
  if (q==5){ a = cq_theta(a,0.9); ang = 0.7; }
  b = cq_theta(b, ang);         /* the Ry stem of the peeled angle select */
  printf("%d %d\n", cq_measure(a), cq_measure(b)); return 0;
}
