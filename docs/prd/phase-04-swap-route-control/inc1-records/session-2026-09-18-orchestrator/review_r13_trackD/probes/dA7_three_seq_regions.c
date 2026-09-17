// Three sequential regions on ONE CSE'd compare (regions 2 and 3 both cross-block).
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  if (q == 5) r = cq_theta(r, 0.9);
  if (q == 5) r = cq_theta(r, 0.7);
  if (q == 5) r = cq_theta(r, 0.5);
  return cq_measure(q) + cq_measure(r);
}
