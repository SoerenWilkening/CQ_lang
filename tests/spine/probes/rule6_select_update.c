/* tests/spine probe (CR rule 6 in-place update, a select of an update; owner ruling pending 2026-11-26, cq-6wef6):
 * `if (c) y += o;`, which -O1 makes `select c, y + o, y`, lowers as `y += c ? o : 0;` does: the select on the other
 * operand, the in-place gate, the select's _unc. Either arm order, add or xor (with a rail -O1 already
 * selects the operand). */
#include <stdbool.h>
int if_add(unsigned char a0, double ta, double tx) {
  unsigned char a = a0;
  bool x = 0;
  cq_theta(&a, ta);
  cq_theta(&x, tx);
  if (x) a += 7;
  return cq_measure(a) + cq_measure(x);
}
int unless_add(int a0, double ta, int b0, double tb) {
  int a = a0, b = b0;
  cq_theta(&a, ta);
  cq_theta(&b, tb);
  if (!(b > 3)) a += 9;
  return cq_measure(a) + cq_measure(b);
}
int if_xor(unsigned a0, double ta, int b0, double tb) {
  unsigned a = a0;
  int b = b0;
  cq_theta(&a, ta);
  cq_theta(&b, tb);
  if (b < 0) a ^= 0x55;
  return cq_measure(a) + cq_measure(b);
}
