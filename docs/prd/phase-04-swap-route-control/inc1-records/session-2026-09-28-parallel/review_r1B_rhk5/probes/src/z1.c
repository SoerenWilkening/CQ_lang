#include <stdlib.h>
/* r1B z1 — COMPOSITION with z0re's shape: a controlled STATE PREP register `r`
   (constant seed here; z0re makes the seed a runtime value) is the borrowed parent of
   a derived chain whose discharge window holds a clone call reading `r`. */
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  _Bool b = cq_theta((_Bool)(m & 1), 0.4);
  int r = 3;
  if (b) r = cq_theta(3, 0.9);
  int p = r * 3;
  int u = p ^ r;
  int s = h(m, r);
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s);
  r = cq_theta(r, 0.7);
  return ms + cq_measure(r) + cq_measure(b);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
