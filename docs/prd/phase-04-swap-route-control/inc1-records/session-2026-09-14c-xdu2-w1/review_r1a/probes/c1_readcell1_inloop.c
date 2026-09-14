#include <stdbool.h>
/* A read of a DIFFERENT cell (b[1]) INSIDE the write loop. -O1 hoists the
   loop-invariant gep to the preheader, so the promoter's NonRewritable-in-L
   clause (which tests the GEP's block) cannot see the LOAD's block. */
int slice(void) {
  int a = 5, s = 0; bool b[3] = {0};
  for (int i = 0; i < 3; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5); s += b[1]; }
  return s + cq_measure(a);
}
int main(void){ return slice(); }
