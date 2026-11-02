/* Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec c3two.c -o c3two.O1.ll.
 * tests/loops-classical probes (cq-w3cd): a case-3 exit test with several quantum disjuncts (CR rule 14 case 3,
 * rule 8: their disjunction is one flag). */
#include <stdbool.h>
#include "CQ.h"
int t_or(int n, double t) {
  int x = 0, y = 0; cq_theta(&x, t); cq_theta(&y, t); int s = 0;
  for (int i = 0; i < n; i++) { s += x; if ((x == i) | (y == i + 1)) break; }
  return cq_measure(s);
}
int t_bool(int n, double t) {
  bool p = 0, q = 0; cq_theta(&p, t); cq_theta(&q, t / 2); int s = 0;
  for (int i = 0; i < n; i++) { s += 2; if (p | !q) break; }
  return cq_measure(s);
}
int t_do(int n, double t) {
  int x = 0, y = 0; cq_theta(&x, t); cq_theta(&y, t); int s = 0, i = 0;
  do { s += x ^ i; i++; } while (i < n && x != i && y != 2 * i);
  return cq_measure(s);
}
