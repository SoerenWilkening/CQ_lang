/* tests/loops-classical probes, the deferred reverse loop (cq-fx3s, cq-aqbw): a value read after a classically
 * bounded loop is read in place and the reverse loop runs after its readers (CR rule 14; 153, 178). Every entry's
 * last parameter is the trip count n; the runner's deferred group checks the kept rails at n = 2 and n = 3 (no
 * which-path or garbage rail). Regenerate deferred.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../CQ_spec deferred.c -o deferred.O1.ll */
#include "CQ.h"
/* lcw-h1 d3: a loop in a quantum arm; the arm's select reads the exit value, then the reverse */
int f_arm(int x0, double th, int n) {
  int x = x0; cq_theta(&x, th);
  int acc = 0;
  if (x & 4) {
    for (int i = 0; i < n; i++) acc = acc * 3 + (x ^ i);
  }
  return cq_measure(acc);
}
/* lcw-h1 d2: a case-3 loop (quantum break) in an arm with an else value */
int f_arm_brk(int x0, double th, int lim, int n) {
  int x = x0; cq_theta(&x, th);
  int acc = 0;
  if (x & 4) {
    for (int i = 0; i < n; i++) {
      acc += x ^ i;
      if (acc > lim) break;
    }
  } else acc = x * 5;
  return cq_measure(acc);
}
/* lcw-h1 a6: a phase in the trip, the loop in an arm */
int f_arm_phase(int x0, double th, double ph, int n) {
  int x = x0; cq_theta(&x, th);
  int acc = 0;
  if (x & 4) {
    for (int i = 0; i < n; i++) {
      acc += x ^ i;
      if (acc & 1) cq_phi(ph);
    }
  }
  return cq_measure(acc);
}
/* 178's shape: a garbage chain reads the exit value (a phase oracle), then x is rotated: the reverse runs between */
int f_oracle(int x0, double th, int s, int n) {
  int x = x0; cq_theta(&x, th);
  int v = 0;
  for (int i = 0; i < n; i++) v += (x >> i) & 1;
  if (__builtin_popcount(v & s) & 1) cq_phi(3.14159);
  cq_theta(&x, -th);
  return cq_measure(x);
}
