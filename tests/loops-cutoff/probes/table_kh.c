/* tests/loops-cutoff probe, cq-9kcq with owner ruling Q2 of 2026-11-14 (CR 1.4 "Received K", rule 27 "Cutoff": "calls
 * inside the library are rule 18's and pass the received K down"; "the loops of a library usually sit in helpers"):
 * @__cq_k holds the K the running table clone received (-1 elsewhere); a function a table clone reaches by name loads it
 * on entry and cuts its K-loops at the smaller of it and its own K. Owner ruling Q3: rule 6's per-trip clean is made in a
 * loop the received K cuts.
 * Each table function's address escapes (a volatile pointer): its entry calls it through the pointer at K 2 (CQ_K) while
 * every helper's own K is 4 (the default), so a helper's loop runs min(2, B) trips there and its own 4 when called by
 * name from an ordinary entry.
 * The C oracle resolves K per function (it follows no received K), so the §6 check reads its C program from
 * table_kh_c.O1.ll (-DTABLE_K_C): the helpers at the received K, and a by-name call from an ordinary entry going to an
 * identical copy at the helper's own K.
 * Regenerate both:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec table_kh.c -o table_kh.O1.ll
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec -DTABLE_K_C table_kh.c -o table_kh_c.O1.ll */
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
#ifdef TABLE_K_C
/* the C side: the by-name calls from ordinary entries go to copies at the helpers' own K */
__attribute__((noinline)) static unsigned h1o(unsigned x, unsigned a) BODY_H1
__attribute__((noinline)) static unsigned h2o(unsigned x, unsigned a) BODY_H2
#define H1D h1o
#define H2D h2o
CQ_K(h1, 2)
CQ_K(h2, 2)
CQ_K(h3, 2)
CQ_K(h6, 2)
CQ_K(h1o, 4)
CQ_K(h2o, 4)
CQ_K(t2, 2)
CQ_K(r6, 2)
CQ_K(t5, 3)
CQ_K(h5, 3)
CQ_K(g3k, 3)
#else
#define H1D h1
#define H2D h2
CQ_K(g3k, 3)
#endif

/* The table functions, each of its own C type: rule 19's dispatch over a rail pointer runs every function of the
 * pointer's type under its predicate, and a by-name helper's K-loop is not under it (the helper's a_K of a function not
 * selected is kept as well); one candidate per type keeps this probe to the received K.
 * t1, t3, t6: no loop of their own; their helpers' loops are cut at the K they receive */
__attribute__((noinline)) static unsigned t1(unsigned x, unsigned a) { return h1(x, a) + 1; }
__attribute__((noinline)) static unsigned t3(unsigned x, unsigned short a) { return h3(x, a) ^ 5; }
__attribute__((noinline)) static unsigned long long t6(unsigned x, unsigned c) { return h6(x, c); }
/* t7, t8: one type, for the classical pointer (only the function it holds runs) */
__attribute__((noinline)) static unsigned t7(unsigned x, unsigned a, unsigned b) { return h1(x, a) + b; }
__attribute__((noinline)) static unsigned t8(unsigned x, unsigned a, unsigned b) { return h3(x, a) ^ b; }
/* t2 holds a K-loop itself and calls a helper (both cut at the received K) */
__attribute__((noinline)) static unsigned t2(unsigned x, unsigned long long a) {
  unsigned n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return n * 100 + h2(x, a);
}
/* t5: like t2, with its own helper; called only from g3k (K 3) */
__attribute__((noinline)) static unsigned t5(unsigned x, unsigned char a) {
  unsigned m = h5(x, a + 1), n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return n * 100 + m;
}
/* r6: rule 6 in the table clone's own cut loop: a carried s adding a measured outcome (review2 R1 m1 with no classical
 * conjunct), cut at the received K */
__attribute__((noinline)) static unsigned short r6(unsigned x, unsigned m) {
  unsigned s = 0;
  while (x > 2) { x -= 3; s += cq_measure(x & 1); }
  return s * 256 + x + m;
}
unsigned (*volatile p1)(unsigned, unsigned) = t1;
unsigned (*volatile p2)(unsigned, unsigned long long) = t2;
unsigned (*volatile p3)(unsigned, unsigned short) = t3;
unsigned long long (*volatile p6)(unsigned, unsigned) = t6;
unsigned (*volatile p5)(unsigned, unsigned char) = t5;

CQ_K(kh_1, 2)
CQ_K(kh_2, 2)
CQ_K(kh_3, 2)
CQ_K(kh_6, 2)
CQ_K(kh_r6, 2)
CQ_K(kh_cls, 2)
CQ_K(kh_twin, 2)
CQ_K(kh_after, 2)
CQ_K(kh_seq, 2)

/* a rail pointer (the _ctl table clone) at received K 2 */
unsigned kh_1(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p1(x, a)); }
unsigned kh_2(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p2(x, a)); }
unsigned kh_3(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(p3(x, (unsigned short)a)); }
unsigned kh_6(unsigned x0, double th, unsigned c) { unsigned x = x0; cq_theta(&x, th); return (unsigned)cq_measure(p6(x, c)); }
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
  unsigned (*fp)(unsigned, unsigned, unsigned) = (sel & 1) ? t7 : t8;
  return cq_measure(fp(x, a, 5));
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
__attribute__((noinline)) unsigned g3k(unsigned x, unsigned char a, unsigned short b) { return p5(x, a) + b; }
unsigned kh_seq(unsigned x0, double th, unsigned a) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = p1(x, a);
  unsigned s = g3k(x, (unsigned char)a, 1);
  unsigned d = H2D(x, a);
  return cq_measure(r) * 1000000 + cq_measure(s) * 1000 + cq_measure(d);
}
/* an ordinary entry calling the helpers by name only: never a table clone in its path, @__cq_k reads -1, own K 4 */
unsigned kh_direct(unsigned x0, double th, unsigned a) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(H1D(x, a)) * 1000 + cq_measure(H2D(x, a));
}
