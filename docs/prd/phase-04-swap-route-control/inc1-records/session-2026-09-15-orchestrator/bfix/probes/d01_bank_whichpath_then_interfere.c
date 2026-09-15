#include <stdbool.h>
/* The bd `s82e` shape, through a rail BANK: per-bit which-path rails parked in
 * memory, then the source register re-rotated NON-DIAGONALLY and measured. */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  bool b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = (q >> i) & 1;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  q = cq_theta(q, 0.9);                 /* NON-DIAGONAL, after the bank */
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
