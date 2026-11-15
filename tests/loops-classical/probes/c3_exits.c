/* tests/loops-classical probe (cq-2xl5, CR rules 2, 5, 14 case 3): a case-3 loop with several classical exit tests
 * (the bound and i == m). T joins each exit edge's res; the measured exit value s is a select over the copies out
 * after the loop, so those copies are read by a template, not kept: the deferred reverse un-copies them. me_eq: a
 * quantum test (x ^ i) == 5; me_lt: x < i. Regenerate c3_exits.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec c3_exits.c -o c3_exits.O1.ll */
#include "CQ.h"
int g;
int me_eq(int x0, double th, int n, int m) {
  int x = x0; cq_theta(&x, th);
  int s = 0, i;
  for (i = 0; i < n; i++) {
    if ((x ^ i) == 5) { cq_phi(0.3); break; }
    if (i == m) { g = 1; break; }
    s += x ^ i;
  }
  return cq_measure(s) + i;
}
int me_lt(int x0, double th, int n, int m) {
  int x = x0; cq_theta(&x, th);
  int s = 0, i;
  for (i = 0; i < n; i++) {
    if (x < i) { cq_phi(0.3); break; }
    if (i == m) { g = 1; break; }
    s += x ^ i;
  }
  return cq_measure(s) + i;
}
