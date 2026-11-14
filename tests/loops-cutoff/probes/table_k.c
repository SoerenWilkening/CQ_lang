/* tests/loops-cutoff probe, cq-9kcq (CR rule 27 "Cutoff": "Inside the clone and its callees every quantum-exit loop runs
 * min(K, B) trips ...; no K variant of a library exists"; §1.4: a table clone takes "the cutoff K as a classical i32";
 * rule 19: a call through a pointer passes "the K of the caller's enclosing function"). Each callee's address escapes,
 * so it has a table clone; each entry calls it through a pointer with CQ_K(entry, 2), while the callee's own K is 4.
 * The table clone must run min(2, B) trips and keep a_K after the second trip.
 * The C oracle resolves K per function from the module (it does not follow a received K), so the §6 check reads its C
 * program from table_k_c.O1.ll: the same source with CQ_K(<callee>, 2) added (TABLE_K_C below), which caps each callee's
 * loop at the K its table clone receives here. The lowering reads table_k.O1.ll (callees at K 4).
 * Regenerate both:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec table_k.c -o table_k.O1.ll
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec -DTABLE_K_C table_k.c -o table_k_c.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static unsigned kf(unsigned x, unsigned a) {   /* body form (05) */
  unsigned n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return n;
}
__attribute__((noinline)) static unsigned km(unsigned x, unsigned a) {   /* two quantum exits */
  unsigned n = 0;
  for (;;) {
    if (x < 9) break;
    x = x * a + 1;
    if ((x & 7) == 3) { n += 100; break; }
    n++;
  }
  return n;
}
__attribute__((noinline)) static unsigned kn(unsigned x, unsigned a) {   /* nested K-loops (68) */
  unsigned n = 0;
  while (x > 9) {
    unsigned y = x;
    while (y & 1) { y >>= 1; n++; }
    x = x * a + 1;
  }
  return n + x;
}
__attribute__((noinline)) static unsigned kd(unsigned x, unsigned a) {   /* do ... while (150) */
  unsigned n = 0;
  do { x = x * a + 1; n += 2; } while (x > 9);
  return n;
}
__attribute__((noinline)) static unsigned kc(unsigned x, unsigned c) {   /* continue (149); s a rule-6 update */
  unsigned s = 0;
  while (x > 3) { x -= 1; if (x & 1) continue; s += c; }
  return s * 16 + x;
}
__attribute__((noinline)) static unsigned kr(unsigned x, unsigned k) {   /* return inside the K-loop (151) */
  unsigned i = 0;
  for (;;) {
    if (x == k) return i;
    x = x / 2;
    i++;
  }
}
__attribute__((noinline)) static unsigned ks(const unsigned char *p) {   /* an exit on a bus load (203) */
  unsigned n = 0;
  while (p[n] != 0) n++;
  return n;
}
unsigned (*volatile pf)(unsigned, unsigned) = kf;
unsigned (*volatile pm)(unsigned, unsigned) = km;
unsigned (*volatile pn)(unsigned, unsigned) = kn;
unsigned (*volatile pd)(unsigned, unsigned) = kd;
unsigned (*volatile pc)(unsigned, unsigned) = kc;
unsigned (*volatile pr)(unsigned, unsigned) = kr;
unsigned (*volatile ps)(const unsigned char *) = ks;
CQ_K(tk_f, 2)
CQ_K(tk_m, 2)
CQ_K(tk_n, 2)
CQ_K(tk_d, 2)
CQ_K(tk_c, 2)
CQ_K(tk_r, 2)
CQ_K(tk_s, 2)
CQ_K(tk_cls, 2)
#ifdef TABLE_K_C
CQ_K(kf, 2)
CQ_K(km, 2)
CQ_K(kn, 2)
CQ_K(kd, 2)
CQ_K(kc, 2)
CQ_K(kr, 2)
CQ_K(ks, 2)
#endif
unsigned tk_f(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pf(x, a)); }
unsigned tk_m(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pm(x, a)); }
unsigned tk_n(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pn(x, a)); }
unsigned tk_d(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pd(x, a)); }
unsigned tk_c(unsigned x0, double th, unsigned c) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pc(x, c)); }
unsigned tk_r(unsigned x0, double th, unsigned k) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pr(x, k)); }
unsigned tk_s(unsigned x0, double th) {
  unsigned char b[8] = {1, 2, 3, 4, 5, 6, 7, 0};
  unsigned x = x0 & 7; cq_theta(&x, th);
  b[x] = 0;
  return cq_measure(ps(b));
}
/* a classical pointer (a select of two addresses on a classical argument): __cq_clone_resolve's forward table clone */
unsigned tk_cls(unsigned x0, double th, unsigned a, unsigned sel) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned (*fp)(unsigned, unsigned) = (sel & 1) ? kf : kd;
  return cq_measure(fp(x, a));
}
