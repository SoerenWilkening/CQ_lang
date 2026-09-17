// ATTACK 4: region 1 is a VALUE arm, region 2 a cross-block (CSE'd) region.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int a = 7;
  if (q == 5) a = 2;                  /* region 1 -- VALUE arm */
  if (q == 5) r = cq_theta(r, 0.7);   /* region 2 -- Pred = region 1's merge */
  return cq_measure(a) + cq_measure(r);
}
