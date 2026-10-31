/* tests/loops-classical probes, CR rule 6 on carried values (cq-b13w). Every entry's last parameter is the trip
 * count n; the kept rails must not depend on n and must be what straight-line rule 6 keeps (the runner's rule6
 * group checks both at n = 2 and n = 3). Regenerate rule6.O1.ll: clang -O1 -S -emit-llvm -target
 * x86_64-apple-macosx16.0.0 -I ../CQ_spec rule6.c -o rule6.O1.ll */
#include "CQ.h"
/* lcw-h2 b3: the dead old value of a bijective update rotated in its trip: keeps q, the measured s */
int r_b3(int q0, double th, int n) {
  int q = q0; cq_theta(&q, th);
  int s = 5;
  for (int i = 0; i < n; i++) { s = s ^ q; cq_theta(&s, th); }
  return cq_measure(s);
}
/* lcw-h2 c2: the register before the loop is dead after it: keeps the measured q only */
int r_c2(int q0, double th, int n) {
  int q = q0; cq_theta(&q, th);
  for (int i = 0; i < n; i++) q ^= i * i;
  cq_theta(&q, th);
  return cq_measure(q);
}
/* a rail update (sub, z - y) and mul by an odd literal, garbage chain read after the loop: keeps x, measured s */
int r_sub(int x0, double th, int n) {
  int x = x0; cq_theta(&x, th);
  int s = 7;
  for (int i = 0; i < n; i++) s = (x - s) * 3;
  return cq_measure(s);
}
/* the initial value is read after the loop (not dead): a copy enters the loop; keeps x, t, measured s */
int r_live(int x0, double th, int n) {
  int x = x0; cq_theta(&x, th);
  int t = x + 1; cq_theta(&t, th);
  int s = t;
  for (int i = 0; i < n; i++) { s += x; cq_theta(&s, th); }
  return cq_measure(s) + cq_measure(t);
}
/* fneg rotated per trip (f64): keeps x, measured s */
double r_fneg(double x0, double th, int n) {
  double x = x0; cq_theta(&x, th);
  double s = x * 2.0;
  for (int i = 0; i < n; i++) { s = -s; cq_theta(&s, th); }
  return cq_measure(s);
}
/* rule 14 case 3: s advances by select(a, s + x, s); keeps x, measured s */
int r_c3(int x0, double th, int k, int n) {
  int x = x0; cq_theta(&x, th);
  int s = 1;
  for (int i = 0; i < n; i++) { s += x; if (x == i + k) break; }
  return cq_measure(s);
}
