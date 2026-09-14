/* F-U1 attack 1: the source comment's "ONE OBJECT, READ TWICE" story.
   Here the SEED and the phi's straight-through incoming are TWO DIFFERENT
   uninitialized objects. -O1 spells both `undef`, so the IR is indistinguishable
   from u2's. Does the normalizer fire, and is the resulting circuit right? */
#include <CQ.h>
int f(int c) {
  _Bool x;   /* object A -- the seed          */
  _Bool y;   /* object B -- the other incoming */
  _Bool r;
  if (c) r = cq_theta(x, 0.5); else r = y;
  return cq_measure(r);
}
