#include <stdio.h>

int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4);
  int m = 5;
  if (q==5){ a = cq_theta(a,0.9); m = 7; }
  int z=1; if (m==7) z=cq_theta(z,0.2); printf("%d %d\n", cq_measure(a), cq_measure(z));
  return 0;
}
