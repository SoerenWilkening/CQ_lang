#include "CQ.h"
/* cq-p8r6 (CR rules 6, 18): a clone overwrites a field of a caller's slot RECORD with a rule-6 bijection, the old
   value dead after the call and no twin (the new content is measured): outside the _inv<c> scope, so the old rail
   would be kept silently; the pass stops loudly. */
struct pr { int a; int b; };
static __attribute__((noinline)) void dbl(struct pr *p, int n) { p->a = p->a * 3 + n; }
int inv_unbuilt_record(int a0, double t, int b0, double tb, int n) {
  struct pr s = {a0, b0};
  cq_theta(&s.a, t);
  cq_theta(&s.b, tb);
  dbl(&s, n);
  return cq_measure(s.a) + cq_measure(s.b);
}
