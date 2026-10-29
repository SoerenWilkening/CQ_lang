/* tests/loops-classical probes (cq-w1-loops-classical): rule 14 cases 1 and 3 without a zero-trip guard, so the
 * exit value is read directly (no exit merge): each entry is checked §6 against its own C program
 * (cqcheck user). Regenerate loops.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../CQ_spec loops.c -o loops.O1.ll */
#include "CQ.h"
/* 25 */
int p_acc(int x0, double th, int n, int c) {
  int x = x0; cq_theta(&x, th);
  int acc = 0, i = 0;
  do { acc = acc * c + x; i++; } while (i < n);
  return cq_measure(acc);
}
/* 26 break_with_body as do-while */
int p_brk(int x0, double th, int n, int k, int c) {
  int x = x0; cq_theta(&x, th);
  int acc = 0, i = 0;
  do { acc = acc * c + i; i++; if (x == i + k) break; } while (i < n);
  return cq_measure(acc);
}
/* 27 nested */
int p_nest(int x0, double th, int n, int m, int c) {
  int x = x0; cq_theta(&x, th);
  int acc = 0, i = 0;
  do { int j = 0; do { acc = acc + (x ^ (i * c + j)); j++; } while (j < m); i++; } while (i < n);
  return cq_measure(acc);
}
/* 62 arm in loop */
int p_mod(unsigned e0, double th, unsigned a, unsigned N, int nbits) {
  unsigned e = e0; cq_theta(&e, th);
  unsigned r = 1, base = a % N; int i = 0;
  do { if ((e >> i) & 1) r = (r * base) % N; base = (base * base) % N; i++; } while (i < nbits);
  int m = cq_measure(r);
  return m + cq_measure(e);
}
/* 139 nested with inner break */
int p_nb(int x0, double th, int n, int m, int lim) {
  int x = x0; cq_theta(&x, th);
  int acc = 0, i = 0;
  do { int j = 0; do { acc += x ^ (i + j); j++; if (acc > lim) break; } while (j < m); i++; } while (i < n);
  return cq_measure(acc);
}
/* 28 fp horner */
double p_horner(double x0, double th, const double *coef, int n) {
  double x = x0; cq_theta(&x, th);
  double s = coef[0]; int i = 1;
  do { s = s * x + coef[i]; i++; } while (i < n);
  return cq_measure(s);
}
/* case 3 inside a quantum arm: the trip predicate starts at the arm flag */
int p_arm(int x0, double th, int n, int k, int c) {
  int x = x0; cq_theta(&x, th);
  int acc = 0;
  if (x & 1) { int i = 0; do { acc = acc * c + i; i++; if (x == i + k) break; } while (i < n); }
  return cq_measure(acc);
}
/* a phase under a quantum arm in a classical-bound loop */
int p_phase(int x0, double th, int n, double ph) {
  int x = x0; cq_theta(&x, th);
  int i = 0;
  do { if ((x >> i) & 1) cq_phi(ph); i++; } while (i < n);
  return cq_measure(x);
}
/* a classical branch in the body joining handles */
int p_cjoin(int x0, double th, int n, int c) {
  int x = x0; cq_theta(&x, th);
  int acc = 0, i = 0;
  do { if (i & c) acc = acc + x; else acc = acc ^ i; i++; } while (i < n);
  return cq_measure(acc);
}
/* case 3 with a phase in the trip: under the trip rail */
int p_tphase(int x0, double th, int n, int k, double ph) {
  int x = x0; cq_theta(&x, th);
  int acc = 0, i = 0;
  do { cq_phi(ph); acc += i; i++; if (x == i + k) break; } while (i < n);
  return cq_measure(acc);
}
