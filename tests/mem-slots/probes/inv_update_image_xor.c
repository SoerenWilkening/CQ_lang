#include "CQ.h"
/* cq-necw (CR §1.4 _inv<c>, rules 6, 18; gate 2a review calls-h2 g1): as inv_update_image, the new content
   read by c ^ (b * 5) with both operands dead: rule 6 cleans the new content from the xor, b * 5 is uncomputed
   (rule 5), the old register is cleaned through _inv0 and no twin runs. */
static __attribute__((noinline)) void bump(int *p, int x) { *p = *p * 3 + x; }
int inv_update_image_xor(int a0, int b0, double th) {
  int c = a0;
  cq_theta(&c, th);
  int b = b0;
  cq_theta(&b, th);
  bump(&c, b);
  int b2 = b * 5;
  return c ^ b2;
}
