#include <stdio.h>

int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4);
  int m = 5;
  if (q==5){ a = cq_theta(a,0.9); m = 7; }
  int t = 1 << (m & 3); printf("%d %d\n", cq_measure(a), cq_measure(t));
  return 0;
}
