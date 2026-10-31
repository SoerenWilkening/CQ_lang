/* tests/loops-cutoff probes, CR rule 6 on carried values of a K-cutoff loop (rule 14 case 2, cq-41v2): the
 * analogues of tests/loops-classical/probes/rule6.c with a quantum exit test. The old value of a bijective
 * carried update is dead after it; no old rail may be kept: the kept rails are the straight-line rule 6
 * multiset plus rule 14's overflow flag (the runner checks every sample). The in-trip rotated form
 * (s ^= q; cq_theta(&s)) is cq-99f7 (a call in a K-loop body). Regenerate rule6.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec rule6.c -o rule6.O1.ll */
#include "CQ.h"
/* lcw-h2 b3 with a quantum exit (unrotated): keeps q, the measured s */
int k_xq(int q0, double th) {
  int q = q0; cq_theta(&q, th);
  int s = 5;
  for (int i = 0; i < q; i++) s = s ^ q;
  return cq_measure(s);
}
/* sub chain (x - s) * 3, quantum exit on x: keeps x, the measured s */
int k_sub(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int s = 7;
  for (int i = 0; i < x; i++) s = (x - s) * 3;
  return cq_measure(s);
}
/* followed by an Ry on the final value (the old values must be gone before it): keeps q, the measured s */
int k_xr(int q0, double th) {
  int q = q0; cq_theta(&q, th);
  int s = 5;
  for (int i = 0; i < q; i++) s = s ^ q;
  cq_theta(&s, th);
  return cq_measure(s);
}
