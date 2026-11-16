/* tests/loops-cutoff probe (cq-n1hy7; CR rules 5, 14): a value made in the trip of a quantum-exit K-loop and read after
 * the loop is an exit value: the last executed trip's, wired out before the reverse loop undoes the trips. One entry per
 * reader shape. Checked against the C program. At 20e75a9b te_sub, te_meas, te_store, te_ret, te_rot and te_cbr freed rails
 * dirty: rule 6 consumed the last trip's exit rail through the reader's inverse (a - b: add(s, b) + copy), and the reverse
 * loop replayed that clean-up on every trip's instance. Mutant prev_trip: te_sub's exit value read from the trip before.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_exit.c -o trip_exit.O1.ll */
#include "CQ.h"
int te_G;
__attribute__((noinline)) static int te_g(int a) { return a * 5 + 1; }

/* (i) read after the loop by itself, measured; the exit test reads it too (-O1 sinks a value no trip reads) */
int te_direct(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a;
  do { a = (int)x * (int)x + 3; x >>= 1; } while (a & 4);
  return cq_measure(a);
}
/* (ii, iv) two trip values read by the exit test and combined by a template after the loop (the bead's sexit) */
int te_sub(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a, b;
  do { a = (int)x * (int)x; b = (int)x * 15; x >>= 1; } while ((a ^ b) & 2);
  return cq_measure(a - b);
}
/* (i, iii) read after the loop by a template with a header phi's exit value (x), measured */
int te_meas(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a;
  do { a = (int)x * (int)x; x >>= 1; } while (a & 4);
  return cq_measure(a + (int)x);
}
/* (iii) stored */
int te_store(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a, b;
  do { a = (int)x * (int)x; b = (int)x * 15; x >>= 1; } while ((a ^ b) & 2);
  te_G = a - b;
  return cq_measure(te_G ^ 1);
}
/* (iii) returned unmeasured */
int te_ret(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a, b;
  do { a = (int)x * (int)x; b = (int)x * 15; x >>= 1; } while ((a ^ b) & 2);
  return a - b;
}
/* (iii) the target of a rotation */
int te_rot(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned a, b;
  do { a = x * x; b = x * 15; x >>= 1; } while ((a ^ b) & 2);
  a -= b;
  cq_theta(&a, th);
  return cq_measure(a);
}
/* (iv) also read by the next trip: b is the previous trip's a */
int te_next(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a = 1, b;
  do { b = a; a = ((int)x * (int)x) ^ a; x >>= 1; } while ((a ^ b) & 2);
  return cq_measure(a - b);
}
/* (v) made in a classical branch of the trip */
int te_cbr(unsigned x0, double th, int c) {
  unsigned x = x0; cq_theta(&x, th);
  int a, b;
  do {
    if (c & 1) a = te_g((int)x); else a = (int)x * (int)x;
    b = (int)x * 15; x >>= 1;
  } while ((a ^ b) & 2);
  return cq_measure(a - b);
}
/* (vi) the region form: made in the header test region */
int te_region(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a, b;
  for (;;) {
    a = (int)x * (int)x; b = (int)x * 15;
    if ((a ^ b) & 2) break;
    x >>= 1;
    if (x & 64) return cq_measure((int)x);
  }
  return cq_measure(a - b);
}
/* (vii) a nested K-loop's trip values, read after it in the enclosing trip */
int te_nested(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = x ^ 5;
  int s = 0;
  do {
    int a, b;
    do { a = (int)x * (int)x; b = (int)x * 15; x >>= 1; } while ((a ^ b) & 2);
    s += a - b; y >>= 1;
  } while (y & 1);
  return cq_measure(s);
}
