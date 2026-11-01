#include "CQ.h"
/* cq-kwmu (CR rules 2, 20), mem-slots part: 61's prep. -O1 writes the second in-place rotation as
   cq_theta of the first one's result, stored back into the same cell. That use of the first result is the
   cell's own rail rotated again, not a read through another holder: the first store is a move (nothing
   emitted), never a basis copy (a copy-out leaves the rotated rail entangled with the copy). */
__attribute__((noinline)) static void prep(unsigned *x, unsigned y, double t1, double t2, unsigned k) {
  cq_theta(x, t1);
  if (y > k) cq_theta(x, t2);
}
unsigned clone_rotate_chain(unsigned x0, double t, unsigned y, unsigned k) {
  unsigned x = x0; cq_theta(&x, t);
  prep(&x, y, t, t, k);
  prep(&x, y, t, t, k);
  return cq_measure(x);
}
