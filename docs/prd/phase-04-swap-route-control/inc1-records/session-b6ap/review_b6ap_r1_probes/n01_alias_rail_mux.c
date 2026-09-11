/* both peeled incomings are the SAME physical rail at two points of its history
   (a chained cq_theta) — distinct SSA, one register (Rule 8 / stale record). */
#include <stdio.h>
int main(void){
  int q = cq_theta(0,0.3), a = cq_theta(0,0.4);
  int p  = cq_theta(0,0.4);
  int p2 = cq_theta(p,0.6);      /* SAME rail as p after lowerRotations */
  int m = p2;
  if (q==5){ a = cq_theta(a,0.9); m = p; }
  printf("%d %d %d\n", cq_measure(a), cq_measure(m), cq_measure(p2));
  return 0;
}
