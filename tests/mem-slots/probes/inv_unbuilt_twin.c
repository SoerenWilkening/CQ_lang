#include "CQ.h"
/* cq-p8r6: a record cell the clone overwrites, but the twin runs (its new content is garbage after a measured
   sum): the twin restores the old content, so no clean-up and no stop (rule 18: _inv and _unc never both). */
struct pr { int a; int b; };
static __attribute__((noinline)) void dbl(struct pr *p, int n) { p->a = p->a * 3 + n; }
int inv_unbuilt_twin(int a0, double t, int b0, double tb, int n) {
  struct pr s = {a0, b0};
  cq_theta(&s.a, t);
  cq_theta(&s.b, tb);
  dbl(&s, n);
  return cq_measure(s.a + s.b);
}
