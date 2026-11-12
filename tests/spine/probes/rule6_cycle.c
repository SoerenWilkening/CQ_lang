/* tests/spine probe (CR rule 6, cq-4wbdf, cq-f725): a cycle that runs through another rail's clean-up. In cyc_arm,
 * s = sext x + a and then s + u, u a select under the quantum test x & 1: rule 6 would clean sext x against s and s
 * against s + u, but u's uncompute reads x & 1, which reads sext x. No order frees all three; the clean-up of sext x
 * gives way to its plain item and s is cleaned against the sum. cyc_mem: cq-f725's program (-O1 makes the same shape). */
#include <string.h>
__attribute__((noinline)) static int g(int d) { return d * d + 1; }
int cyc_arm(signed char x0, double th, int a, int d) {
  signed char x = x0;
  cq_theta(&x, th);
  int u = 0;
  if (x & 1)
    u = g(d);
  return cq_measure(a + u + x);
}
int cyc_mem(int x, int y, double th) {
  int b[4];
  cq_theta(&x, th);
  cq_theta(&y, th);
  b[0] = x; b[1] = y; b[2] = x + y; b[3] = 7;
  if (x & 1)
    memset(b, 0, 8);
  return cq_measure(b[0] + 2 * b[1] + 3 * b[2] + b[3]);
}
