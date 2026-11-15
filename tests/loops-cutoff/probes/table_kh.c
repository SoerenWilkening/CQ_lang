/* tests/loops-cutoff probe, cq-9kcq with owner ruling Q2 of 2026-11-14 (CR 1.4 "Received K", rule 27 "Cutoff": "calls
 * inside the library are rule 18's and pass the received K down"; "the loops of a library usually sit in helpers"):
 * @__cq_k holds the K the running table clone received (-1 elsewhere); a function a table clone reaches by name loads it
 * on entry and runs its K-loops at it in place of its own K (owner 2026-11-15: smaller or larger). Owner ruling Q3: rule 6's per-trip clean is made in a
 * loop the received K cuts.
 * Each table function's address escapes (a volatile pointer): its entry calls it through the pointer at K 2 (CQ_K) while
 * every helper's own K is 4 (the default), so a helper's loop runs min(2, B) trips there and its own 4 when called by
 * name from an ordinary entry.
 * The C oracle runs each loop at the K the circuit uses, the received K included (cqo_rt.c k_recv, cq-fy1k5), so
 * the §6 check reads this program's own C module.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec table_kh.c -o table_kh.O1.ll */
#include "CQ.h"

#define BODY_H1 { unsigned n = 0; while (x & 1) { x = (x >> 1) | (a << 31); n++; } return n; }
#define BODY_H2 { unsigned n = 0; while (x & 1) { x >>= 1; n++; } return n * 8 + x; }
#define BODY_H3 { unsigned n = 0; while (x > 9) { x = x * a + 1; n += 2; } return n + h2(x, a); }
#define BODY_H6 { unsigned s = 0; while (x > 9) { x = x * c + 1; s += x; } return s * 64 + x; }

/* h1: a helper holding a K-loop (05's body form) */
__attribute__((noinline)) static unsigned h1(unsigned x, unsigned a) BODY_H1
/* h2, h3: nested by-name helpers, a K-loop in each (h3 calls h2 after its own loop) */
__attribute__((noinline)) static unsigned h2(unsigned x, unsigned a) BODY_H2
__attribute__((noinline)) static unsigned h3(unsigned x, unsigned a) BODY_H3
/* h6: rule 6's per-trip clean of s (s read in the loop only by its bijective update) in a loop the received K cuts */
__attribute__((noinline)) static unsigned h6(unsigned x, unsigned c) BODY_H6
/* h5: reached only from t5, which g3k calls at K 3 */
__attribute__((noinline)) static unsigned h5(unsigned x, unsigned a) BODY_H1
/* hr: quantum-depth recursion (rule 14) in a helper: cut at the received K */
#define BODY_HR { if (x & 1) { unsigned r = HR_SELF(x >> 1); return r * r + 1; } return x; }
#define HR_SELF hr
__attribute__((noinline)) static unsigned hr(unsigned x) BODY_HR
#undef HR_SELF
/* tq: a table function holding a K-loop, reached only through pq from the helper hp, which passes its received K on */
__attribute__((noinline)) static unsigned tq(unsigned x, unsigned a) {
  unsigned n = 0;
  while (x & 2) { x = (x >> 2) | (a << 30); n++; }   /* a value function of its own: no other loop's a_K matches it */
  return n;
}
unsigned (*volatile pq)(unsigned, unsigned) = tq;
__attribute__((noinline)) static unsigned hp(unsigned x, unsigned a) { return pq(x, a) * 2; }
#define H1D h1
#define H2D h2
#define HRD hr
CQ_K(g3k, 3)

/* The table functions, all of one C type: rule 19's dispatch over a rail pointer runs every one of them under its
 * predicate, each calling its helpers by name unguarded (CR rule 19: a callee of templates on SSA values only), so the
 * helpers of the functions not selected keep their a_K too, a cut one included (cq-wkzu9).
 * t1, t3, t6: no loop of their own; their helpers' loops are cut at the K they receive */
__attribute__((noinline)) static unsigned t1(unsigned x, unsigned a) { return h1(x, a) + 1; }
__attribute__((noinline)) static unsigned t3(unsigned x, unsigned a) { return h3(x, a) ^ 5; }
__attribute__((noinline)) static unsigned t6(unsigned x, unsigned c) { return h6(x, c); }
/* t2 holds a K-loop itself and calls a helper (both cut at the received K) */
__attribute__((noinline)) static unsigned t2(unsigned x, unsigned a) {
  unsigned n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return n * 100 + h2(x, a);
}
/* t5: like t2, with its own helper; called only from g3k (K 3) */
__attribute__((noinline)) static unsigned t5(unsigned x, unsigned a) {
  unsigned m = h5(x, a + 1), n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return n * 100 + m;
}
/* r6: rule 6 in the table clone's own cut loop: a carried s adding a measured outcome (review2 R1 m1 with no classical
 * conjunct), cut at the received K. Of its own type and reached through a classical pointer: a measurement in a K-loop
 * of a _t_ctl clone fails on its own (cq-jr1r0), at any K. */
__attribute__((noinline)) static unsigned short r6(unsigned x, unsigned m) {
  unsigned s = 0;
  while (x > 2) { x -= 3; s += cq_measure(x & 1); }
  return s * 256 + x + m;
}
unsigned (*volatile p1)(unsigned, unsigned) = t1;
unsigned (*volatile p2)(unsigned, unsigned) = t2;
unsigned (*volatile p3)(unsigned, unsigned) = t3;
unsigned (*volatile p6)(unsigned, unsigned) = t6;
unsigned (*volatile p5)(unsigned, unsigned) = t5;
/* t7: a helper's quantum-depth recursion; t8: a helper calling through a pointer */
__attribute__((noinline)) static unsigned t7(unsigned x, unsigned a) { return hr(x) + a; }
__attribute__((noinline)) static unsigned t8(unsigned x, unsigned a) { return hp(x, a) + 1; }
unsigned (*volatile p7)(unsigned, unsigned) = t7;
unsigned (*volatile p8)(unsigned, unsigned) = t8;

CQ_K(kh_1, 2)
CQ_K(kh_2, 2)
CQ_K(kh_3, 2)
CQ_K(kh_6, 2)
CQ_K(kh_r6, 2)
CQ_K(kh_cls, 2)
CQ_K(kh_twin, 2)
CQ_K(kh_after, 2)
CQ_K(kh_seq, 2)
CQ_K(kh_rec, 2)
CQ_K(kh_ptr, 2)

/* a rail pointer (the _ctl table clone) at received K 2 */
unsigned kh_1(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p1(x, a)); }
unsigned kh_2(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p2(x, a)); }
unsigned kh_3(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p3(x, a)); }
unsigned kh_6(unsigned x0, double th, unsigned c) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p6(x, c)); }
/* r6 through a classical pointer (its forward table clone; r6 or q6 on m's low bit) */
__attribute__((noinline)) static unsigned short q6(unsigned x, unsigned m) { return (unsigned short)(x + m); }
unsigned kh_r6(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned short (*fp)(unsigned, unsigned) = (m & 1) ? r6 : q6;
  return cq_measure(fp(x, m));
}
/* a classical pointer: the forward table clone */
unsigned kh_cls(unsigned x0, double th, unsigned a, unsigned sel) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned (*fp)(unsigned, unsigned) = (sel & 1) ? t1 : t3;
  return cq_measure(fp(x, a));
}
/* the result read by something other than a measurement: the table clone's twin runs (and the helper's twin in it) */
unsigned kh_twin(unsigned x0, double th, unsigned a) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = p1(x, a);
  return cq_measure(x + (r & 3));
}
/* restore on return: after the table call returned, a by-name call of the same helper from this ordinary entry reads
 * -1 again and runs the helper's own K 4 */
unsigned kh_after(unsigned x0, double th, unsigned a) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = p1(x, a);
  unsigned d = H1D(x >> 2, a);   /* another value function than the table call's a_K */
  return cq_measure(r) * 1000 + cq_measure(d);
}
/* a second table clone with another K afterwards: g3k (K 3) calls t5 through a pointer, passing its own K 3 (t5 and its
 * helper h5 cut at 3); then a by-name call of h2 from this entry runs at its own K 4 */
__attribute__((noinline)) unsigned g3k(unsigned x, unsigned a) { return p5(x, a); }
unsigned kh_seq(unsigned x0, double th, unsigned a) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = p1(x, a);
  unsigned s = g3k(x, a);
  unsigned d = H2D(x, a);
  return cq_measure(r) * 1000000 + cq_measure(s) * 1000 + cq_measure(d);
}
/* an ordinary entry calling the helpers by name only: never a table clone in its path, @__cq_k reads -1, own K 4 */
unsigned kh_direct(unsigned x0, double th, unsigned a) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(H1D(x, a)) * 1000 + cq_measure(H2D(x, a));
}
/* a helper's recursion cut at the received K 2 (own K 4), then the same helper by name from this ordinary entry at 4 */
unsigned kh_rec(unsigned x0, double th, unsigned a) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = p7(x, a);
  unsigned d = HRD(x >> 3);
  return cq_measure(r) * 1000 + cq_measure(d);
}
/* a helper calling through a pointer passes the K it received (2) to the table clone it reaches (tq, own K 4) */
unsigned kh_ptr(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p8(x, a)); }
