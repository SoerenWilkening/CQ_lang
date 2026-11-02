#include "CQ.h"
/* cq-necw (CR §1.4 _inv<c>, rules 6, 18; gate 2a review calls-h2 d2, vs the inline spelling e2): the clone
   overwrites c[0] with 3*old + b, the old register is dead after the call, and the new content is read once by
   a bijective update (c[0] + c[1]) and then dies. As inline, rule 6 cleans the old register (here through
   _inv0) and the new content from the sum; the twin, which would restore the dead old register and leave it
   live at exit, never runs. Main ran the twin and defined _inv0 unused. */
static __attribute__((noinline)) void bump(int *p, int x) { *p = *p * 3 + x; }
int inv_update_image(int a0, int a1, int b, double th) {
  int c[2] = {a0, a1};
  cq_theta(&c[0], th);
  cq_theta(&c[1], th);
  bump(&c[0], b);
  return c[0] + c[1];
}
