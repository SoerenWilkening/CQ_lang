/* tests/spine probe (CR rule 6 with rule 17, cq-hbydr): a chain of in-place updates before a cq_invert region whose
 * last image the region reads, and whose in-region update is read after the end. The region's own rails are uncomputed
 * inside it and the update recomputed after the end (rule 17); the chain before the region stays in place, and the
 * recomputed update is in place on the old rail, as anywhere else. */
#include <stdbool.h>
int recompute(unsigned char r0, double tr, double tx, double ty) {
  unsigned char rem = r0;
  bool x = 0, y = 0;
  cq_theta(&rem, tr);
  rem ^= 77;
  if (rem >= 5) cq_theta(&x, tx);
  rem -= x ? 5 : 0;
  if (rem >= 9) cq_theta(&y, ty);
  rem -= y ? 9 : 0;
  cq_invert_begin();
  if (rem >= 5) cq_theta(&x, tx);
  rem -= x ? 5 : 0;
  rem -= y ? 3 : 0;
  cq_invert_end();
  rem -= x ? 7 : 0;
  return cq_measure(rem) + cq_measure(x) + cq_measure(y);
}
