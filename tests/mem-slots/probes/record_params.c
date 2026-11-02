#include "CQ.h"
/* cq-e5lj (CR §1.4, rules 20, 26): a clone with several record (byval) pointer formals reads each one's mask digits
   at its own place in the formal list (two_rec: comb_100010); a classical pointer field of a record is a classical
   cell beside the handle fields (ptr_field: rd_010). Main stopped at "several pointer formals" and "a pointer
   field of a slot record that no write fills with a fat pointer". */
struct big { long a, b, c; };
__attribute__((noinline)) static long comb(struct big p, struct big q) { return p.a * 3 + q.b - p.c + q.c; }
long two_rec(long x0, double th, long c) {
  long x = x0; cq_theta(&x, th);
  struct big p = { x, c, 1 }, q = { c, x, 2 };
  return cq_measure(comb(p, q));
}
struct R { int *p; long v; long w; };
__attribute__((noinline)) static long rd(struct R r) { return *r.p + r.v * 2 + r.w; }
long ptr_field(long x0, double th, int y) {
  int t[2] = { y, 3 };
  long x = x0; cq_theta(&x, th);
  struct R r = { &t[y & 1], x, 5 };
  return cq_measure(rd(r));
}
