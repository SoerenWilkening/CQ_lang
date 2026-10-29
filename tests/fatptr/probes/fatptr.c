/* tests/fatptr probes (cq-w1-fatptr): rule 21 pointer compares, each entry checked §6 against its own C program
 * (cqcheck user). Regenerate fatptr.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../CQ_spec fatptr.c -o fatptr.O1.ll */
#include "CQ.h"
int G[8] = {0, 0, 0, 0, 0, 0, 0, 0};
/* two local objects, ne: tag != tag' or idx != idx' */
int f_ne_two(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0};
  int *p = ((x & 1) ? a : b) + ((x >> 1) & 3);
  int *q = b + ((x >> 3) & 3);
  return cq_measure(p != q);
}
/* three local objects through nested selects against a quantum tag of its own */
int f_eq_three(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0}, c[4] = {0, 0, 0, 0};
  int *p = ((x & 1) ? a : ((x & 2) ? b : c)) + ((x >> 2) & 3);
  int *q = ((x & 16) ? c : a) + ((x >> 5) & 3);
  return cq_measure(p == q);
}
/* both select arms carry a quantum cell index (a select of idx rails) */
int f_eq_arms(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0};
  int *p = (x & 1) ? a + ((x >> 1) & 3) : b + ((x >> 3) & 3);
  int *q = a + ((x >> 5) & 3);
  return cq_measure(p == q);
}
/* a global: compares over addresses (globals may alias), ordering within one object */
int f_lt_global(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int *p = ((x & 1) ? G : G + 4) + ((x >> 1) & 3);
  int *q = G + ((x >> 3) & 7);
  return cq_measure(p < q);
}
/* signed cell indices into two globals: a sign-extended quantum index, eq over addresses */
int H[8] = {0, 0, 0, 0, 0, 0, 0, 0};
int f_eq_signed(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int *p = (G + 4) + (x % 4), *q = (H + 4) + ((x >> 4) % 4);
  return cq_measure(p == q);
}
