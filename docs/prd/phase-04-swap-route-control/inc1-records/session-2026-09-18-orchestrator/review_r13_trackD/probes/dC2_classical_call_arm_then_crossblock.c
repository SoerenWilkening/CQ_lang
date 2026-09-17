// 6.5 classical-call arm (region 1) then a cross-block CSE'd region 2.
// Also the ROUND-2 taint-growth route: region 1's %out is a round-2 seed.
#include <CQ.h>
__attribute__((noinline)) static int f(int k) { return k * 3 + 1; }
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int v = 7;
  if (q == 5) v = f(3);               /* region 1 -- 6.5 classical call arm */
  if (q == 5) r = cq_theta(r, 0.9);   /* region 2 -- cross-block */
  return cq_measure(v) + cq_measure(r);
}
