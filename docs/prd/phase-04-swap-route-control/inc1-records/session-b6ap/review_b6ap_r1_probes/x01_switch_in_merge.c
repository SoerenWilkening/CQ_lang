#include <stdio.h>
int main(void){
  int q=cq_theta(0,0.3), a=cq_theta(0,0.4);
  int m=5;
  if (q==5){ a=cq_theta(a,0.9); m=7; }
  int z; switch(q){case 1: z=11;break; case 2: z=22;break; default: z=33;}
  printf("%d %d %d\n", cq_measure(a), cq_measure(m), cq_measure(z)); return 0;
}
