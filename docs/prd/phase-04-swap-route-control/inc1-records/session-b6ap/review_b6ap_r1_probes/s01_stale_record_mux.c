/* the peeled mux READS the PRE-rotation record of a register the arm rotates
   IN PLACE; the emitted copy sits AFTER the region's controlled rotation. */
#include <stdio.h>
int main(void){
  int q = cq_theta(0,0.3), b = cq_theta(0,0.4);
  int m = 5;
  if (q==5){ m = b; b = cq_theta(b, 0.9); }
  printf("%d %d\n", cq_measure(b), cq_measure(m)); return 0;
}
