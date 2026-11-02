#include "CQ.h"
/* cq-necw (CR §1.4 _inv<c>, rules 6, 18): the new content is read by c & 1, no bijection, and dies: it is
   garbage the call's twin uncomputes, which restores the old register (then not dead, rule 18; kept as the
   rotated register, as the inline spelling keeps it). _inv0 never runs at this site, so it is not defined
   (§1.4: defined only when a call site uses it). Main defined it unused. */
static __attribute__((noinline)) void bump(int *p, int x) { *p = *p * 3 + x; }
int inv_update_twin(int a0, int b, double th) {
  int c = a0;
  cq_theta(&c, th);
  bump(&c, b);
  return c & 1;
}
