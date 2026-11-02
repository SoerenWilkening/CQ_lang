/* tests/calls probe (cq-57ju; CR rule 18 partial measurement): a clone returning two quantum fields, one
 * measured and the other dead: the measured field is copied out before the twin. */
#include "CQ.h"
typedef struct { long a, b; } pair;
static __attribute__((noinline)) pair mk(long x) { pair p = {x * 3 + 1, x ^ 5}; return p; }
long pr_first(long v) { long x = v; cq_theta(&x, 0.4); return cq_measure(mk(x).a); }
long pr_second(long v) { long x = v; cq_theta(&x, 0.4); return cq_measure(mk(x).b); }
