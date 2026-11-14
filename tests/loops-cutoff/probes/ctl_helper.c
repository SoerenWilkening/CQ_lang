/* tests/loops-cutoff probe, cq-wkzu9 (CR rule 19 "Address rail": every registered function of the pointer's type runs
 * as its _ctl clone under its flag; rule 19 "Under a quantum predicate": a callee of templates on SSA values only is
 * called unguarded; rule 14: a_K is kept; rule 27 "Cutoff" and owner ruling Q2 of 2026-11-14: a helper a table clone
 * reaches by name cuts its K-loops at the K it receives, the cut a classical exit of the chain). Table functions of one
 * type each call a by-name helper holding a K-loop; an entry calls one of them through a rail pointer, so the helpers
 * of the others run unguarded and keep their a_K, merged by a phi across the cut's join (and across Q10's classical
 * test in hq). Every K is 4: no cut is taken, the a_K is the chain's end; the twin keeps none (169).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec ctl_helper.c -o ctl_helper.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static unsigned h1(unsigned x, unsigned a) { unsigned n = 0; while (x > 9) { x = x * a + 1; n++; } return n; }
__attribute__((noinline)) static unsigned h2(unsigned x, unsigned a) { unsigned n = 0; while (x & 1) { x = (x >> 1) + a; n++; } return n; }
/* a classical conjunct at each test (owner ruling Q10) */
__attribute__((noinline)) static unsigned hq(unsigned x, unsigned m) {
  unsigned i;
  for (i = 0; ((m >> i) & 1) && x > 2; i++) x -= 3;
  return i * 16 + x;
}
__attribute__((noinline)) static unsigned t1(unsigned x, unsigned a) { return h1(x, a) + 1; }
__attribute__((noinline)) static unsigned t2(unsigned x, unsigned a) { return h2(x, a) + 2; }
__attribute__((noinline)) static unsigned t3(unsigned x, unsigned a) { return hq(x, a) + 3; }
unsigned (*volatile p1)(unsigned, unsigned) = t1;
unsigned (*volatile p2)(unsigned, unsigned) = t2;
unsigned (*volatile p3)(unsigned, unsigned) = t3;
unsigned ch1(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p1(x, a)); }
unsigned ch3(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p3(x, a)); }
