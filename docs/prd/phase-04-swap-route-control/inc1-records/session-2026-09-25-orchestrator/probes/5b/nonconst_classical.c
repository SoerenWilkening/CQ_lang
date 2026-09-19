/* BOUNDARY: the non-tainted incoming is a RUNTIME classical value, not a
   constant — there is no seed to allocate, so it must keep declining. */
#include <stdbool.h>
int slice(int u, int k) {
  int q = cq_theta(0, 0.5);
  int a = k;
  if (u > 0) a = q;
  return cq_measure(a);
}
int main(void) { return slice(4, 9); }
