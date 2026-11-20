/* r7 cq-r7mrg (glpk glp_read_mps, _glp_spx_primal): a classically bounded loop with noreturn arms inside a K-loop trip; its
   trip branches classically, so the stop rail handed to the K-loop is a merge of the two arms' rails (rules 9, 14). */
#include <stdlib.h>
int f(unsigned x0, double th, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int s = 0;
  while (x & 7) {
    for (int i = 0; i < 4; i++) {
      if (i == c) {
        if (x == 5)
          abort();
        s += 1;
      } else {
        if (x == 3)
          abort();
        s += 2;
      }
    }
    x >>= 1;
  }
  return s;
}
