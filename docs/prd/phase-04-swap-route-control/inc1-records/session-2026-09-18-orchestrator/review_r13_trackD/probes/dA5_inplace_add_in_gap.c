// ATTACK 3: the dtzb in-place add/xor candidate in the gap. D REMOVED the fence on
// this and relies on an ORDER INTERLOCK (G6 refuses in-place because the mint is a
// later use). Reproduce from C and read the emitted add.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  if (q == 5) r = cq_theta(r, 0.9);   /* region 1 */
  int u = q + 1;                      /* in-place CANDIDATE, squarely in the gap */
  if (q == 5) r = cq_theta(r, 0.7);   /* region 2, CSE'd compare */
  return cq_measure(u) + cq_measure(r);
}
