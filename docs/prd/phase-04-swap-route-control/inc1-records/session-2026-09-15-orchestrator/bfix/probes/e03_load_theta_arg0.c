#include <stdbool.h>
int slice(int seed) {
  bool b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
  bool r = cq_theta(b0[0], 0.25);   /* a bank load as cq_theta arg-0 */
  s += cq_measure(r);
  s += cq_measure(b0[1]);
  s += cq_measure(b0[2]);
  return s;
}
int main(void) { return slice(0); }
