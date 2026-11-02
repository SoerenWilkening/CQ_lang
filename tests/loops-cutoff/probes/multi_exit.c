/* tests/loops-cutoff multi-exit probes (A-loops, wave 2a round 7): CR rule 14 loops with several live exits, an exit
 * into an effect-free dead end, walked pointers (an affine induction is not carried, f981c89) and a clone's _b bound.
 * Each entry is checked §6 against its own C program (cqcheck user). Regenerate multi_exit.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec multi_exit.c -o multi_exit.O1.ll */
#include "CQ.h"
/* memcmp's loop over local slot arrays: a K-loop exiting on a mismatch (header) and on the length (latch). */
int me_cmp(unsigned x0, double tx, unsigned char u0, double tu, unsigned char v0, double tv) {
  unsigned x = x0; cq_theta(&x, tx);
  unsigned char u = u0; cq_theta(&u, tu);
  unsigned char v = v0; cq_theta(&v, tv);
  unsigned char a[3] = {u, v, v}, b[3] = {u, u, v};
  const unsigned char *l = a, *r = b;
  unsigned long n = x & 3;
  for (; n && *l == *r; n--, l++, r++);
  return cq_measure(n ? *l - *r : 0);
}
/* The same loop in a clone: n's call-site bound x & 3 names the clone _b3 and bounds its cutoff. */
__attribute__((noinline)) int me_cmpfn(const unsigned char *l, const unsigned char *r, unsigned long n) {
  for (; n && *l == *r; n--, l++, r++);
  return n ? *l - *r : 0;
}
int me_clone(unsigned x0, double tx, unsigned char u0, double tu, unsigned char v0, double tv) {
  unsigned x = x0; cq_theta(&x, tx);
  unsigned char u = u0; cq_theta(&u, tu);
  unsigned char v = v0; cq_theta(&v, tv);
  unsigned char a[3] = {v, u, u}, b[3] = {v, u, v};
  int c = me_cmpfn(a, b, x & 3);
  return cq_measure((c > 0) - (c < 0));
}
/* A pointer walked to a quantum NUL (87's shape): past the array the cell reads 0. */
int me_walk(unsigned char c0, double th) {
  unsigned char c = c0; cq_theta(&c, th);
  unsigned char s[3];
  s[0] = c; s[1] = c & 1; s[2] = 0;
  int n = 0;
  for (unsigned char *p = s; *p; p++)
    n += 2;
  return cq_measure(n);
}
/* A classical loop whose quantum switch's default is unreachable (131's shape): no exit of the loop. */
int me_dead(int x0, double th, int n) {
  int x = x0; cq_theta(&x, th);
  int acc = 2;
  for (int i = 0; i < n; i++) {
    switch ((x >> (2 * i)) & 3) {
    case 0: acc += 1; break;
    case 1: acc -= i; break;
    case 2: acc ^= 6; break;
    case 3: break;
    }
  }
  return cq_measure(acc);
}
/* A classical bound with a quantum exit before the latch (121's strlen shape, rule 14 case 3): two exits. */
int me_c3(unsigned x0, double t, int c) {
  unsigned x = x0; cq_theta(&x, t);
  int n = 0, cap = c & 7;
  while (n < cap && ((x >> n) & 1))
    n++;
  return cq_measure(n);
}

/* cq-mgkr (cq-uytx): two K-loops in exclusive quantum arms exit into one join whose phi reads each loop's header
 * value (the multi-exit form) and two differing skip values: each unit's join value starts from the skip values'
 * select chain, the later unit from the earlier unit's binding. */
int me_join4(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned n = x & 7, a = 1, b = (x >> 3) & 3;
    unsigned r;
    if ((x >> 5) & 1) {
        if (n > 1) { unsigned i = n; do { r = a; a = a * 3 + b; } while (--i > 1); } else r = 5;
    } else {
        if (n > 1) { unsigned i = n; do { r = b; b = b * 5 + a; if (b > 40) b -= 7; } while (--i > 1); } else r = 9;
    }
    return cq_measure(r);
}

/* cq-mgkr: the join's other incoming is computed in the sibling quantum arm, lowered after the loop: the walker
 * selects it in at the join (LoweringContext::addJoinArm). */
int me_join5(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned n = x & 7, a = 1, b = (x >> 3) & 3;
    unsigned r;
    if ((x >> 5) & 1) {
        if (n > 1) { unsigned i = n; do { r = a; a = a * 3 + b; } while (--i > 1); } else r = b * 7 + 1;
    } else {
        r = b * 11 + a;
    }
    return cq_measure(r);
}
