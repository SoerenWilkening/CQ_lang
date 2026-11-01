#include "CQ.h"
/* cq-bfz4 (CR rule 6 'a cell chosen by a classical index'): the loaded register's bijective update r = a[i] + 1
   is read by another template (r * 3), whose _unc would re-read the old register after its clean-up: the
   construction is built for a measured update only, anything else stops. */
int indexed_unmeasured(int x0, double tx, unsigned j) {
  int x = x0;
  cq_theta(&x, tx);
  int a[2] = {x, 4};
  int r = a[j & 1] + 1;
  return cq_measure(r * 3);
}
