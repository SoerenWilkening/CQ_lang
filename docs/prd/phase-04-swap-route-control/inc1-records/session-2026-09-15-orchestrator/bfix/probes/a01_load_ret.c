#include <stdbool.h>
bool slice(int seed) {
  bool b0[3];
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
  (void)cq_measure(b0[1]);
  (void)cq_measure(b0[2]);
  return b0[0];            /* a bank load RETURNED — not on the allow-list */
}
int main(void) { return slice(0); }
