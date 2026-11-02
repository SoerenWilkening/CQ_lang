/* rule 17 at f684858 (cq-4593): a region whose quantum value is read after it; the rail outlives the region. */
#include "CQ.h"
int p_out(int x0, double th, int c) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  int y = x * c;
  cq_invert_end();
  return cq_measure(y);
}
