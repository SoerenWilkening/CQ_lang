#include "CQ.h"
/* cq-bfz4 (revising cq-dr4o; CR rules 2, 20): a store shares the stored rail between two holders unless an
   in-place write on one of them may follow. Here a[j & 1] is rotated in place after both cells took x and x
   is measured: each cell gets its own rail (a basis copy) and x keeps its own. */
int share_rotated(int x0, double tx, double t2, unsigned j) {
  int x = x0;
  cq_theta(&x, tx);
  int a[2] = {x, x};
  cq_theta(&a[j & 1], t2);
  return cq_measure(a[j & 1]) + cq_measure(x);
}
/* Nothing writes a holder in place: both cells and x share x's rail (no copy). */
int share_plain(int x0, double tx, unsigned j) {
  int x = x0;
  cq_theta(&x, tx);
  int a[2] = {x, x};
  return cq_measure(a[j & 1]) + cq_measure(x);
}
