#include <stdio.h>
volatile double rv = 0.7;
int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4), b=cq_theta(0,0.2);
  double t = rv;               /* run-time, dominates BI */
  double ang = 0.1;
  if (q==5){ a = cq_theta(a,0.9); ang = t; }
  b = cq_theta(b, ang);        /* Ry stem, RUN-TIME arm -> must DECLINE */
  printf("%d %d\n", cq_measure(a), cq_measure(b)); return 0;
}
