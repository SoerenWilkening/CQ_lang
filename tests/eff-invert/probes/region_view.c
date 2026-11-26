/* cq-82krl (rules 3, 17): a view phi's wide value (zext of a bool register) made in a region and read after its end is
   recomputed after the end; kept across it, its _unc followed the region's reversed Ry on the register. */
#include <stdbool.h>
#include "CQ.h"
unsigned char p_view(unsigned char r0) {
  bool x = 0;
  unsigned char r = r0, p = 0;
  cq_theta(&r, 0.0);
  if (r >= 5) cq_theta(&x, 2.0943951023931953);
  p += x ? 1 : 0;
  cq_invert_begin();
  if (r >= 5) cq_theta(&x, 2.0943951023931953);
  p += x ? 1 : 0;
  cq_invert_end();
  if (r >= 5) cq_theta(&x, 2.0943951023931953);
  p += x ? 1 : 0;
  return (unsigned char)(cq_measure(p) + cq_measure(x));
}
