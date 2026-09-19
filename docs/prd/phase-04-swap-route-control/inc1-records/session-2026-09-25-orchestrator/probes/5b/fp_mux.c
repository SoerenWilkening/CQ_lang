/* BOUNDARY: a classical-condition phi over a FLOATING-POINT value. An fp merge
   phi is an ANGLE, not data (CLAUDE.md L9) — must not be promoted to a handle. */
#include <stdbool.h>
int slice(int u) {
  int q = cq_theta(0, 0.5);
  double t = 0.25;
  if (u > 0) t = 0.75;
  int r = cq_theta(q, t);
  return cq_measure(r);
}
int main(void) { return slice(4); }
