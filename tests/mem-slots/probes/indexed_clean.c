#include "CQ.h"
/* cq-bfz4 (CR rule 6 'a cell chosen by a classical index', rules 7, 20, 22; 190's memmove_overlap, extended):
   after the memmove the cells hold x, x, y, the seed 7 and the seed 9 (z is held by no cell any more). The
   memmove moves handles (no copy: nothing writes a holder in place), the seeds are freed directly, and the
   loaded register is cleaned by rule 6 on a classical branch on the index (cells 3 and 4 skipped):
   t = r ^ 3, copy(t, a[i]), uncompute t, free t, free a[i]. Main copied every moved cell and kept them. */
#include <string.h>
int indexed_clean(int x0, double tx, int y0, double ty, int z0, double tz, unsigned j) {
  int x = x0;
  cq_theta(&x, tx);
  int y = y0;
  cq_theta(&y, ty);
  int z = z0;
  cq_theta(&z, tz);
  int a[5] = {x, y, 7, z, 9};
  memmove(a + 1, a, 3 * sizeof(int));   /* a = {x, x, y, 7, 9} */
  return cq_measure(a[j % 5] ^ 3);
}
