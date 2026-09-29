#include <stdlib.h>
/* r2A mc1 — rhk5 x M-C late in-place: the ON plan discharges p (a (b') rail) after
   the clone call and BEFORE `q -= 1`, so M-C may convert the sub in place; the
   oracle cannot see p discharged (clone consumer) and goes out-of-place. */
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  if (p == 9) cq_phi(3.14159);
  int s = h(m, p);
  q -= 1;
  q = cq_theta(q, 0.7);
  return cq_measure(s) + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
