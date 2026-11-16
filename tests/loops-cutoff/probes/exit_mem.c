/* tests/loops-cutoff probe (cq-shndm; CR rules 5, 9, 14, 20 to 22): multi-exit quantum-exit K-loops whose trips access
 * memory, each read after the loop by a return or a measurement. One entry per shape -O1 keeps. Checked against the C
 * program. At d5e32f61 (integ) two entries left the rolled loop's copy of the return value live at exit (the copy at X,
 * made where the zero-trip guard merges the state): em_wcs (musl wcsrtombs' shape: the exit arm that stores *s = 0;
 * *ws = 0 is lowered after the loop through the exit hub; the hub value reaches the return through a phi that also takes
 * the arm's N - n, a quantum choice, which readersKeep followed as if it named the rail: cause 1) and em_ret (the
 * continuation phi joined classically with the skip n == 0 and returned, which the return copies out: cause 2). Every
 * entry passes with the K static copies (4afda23b). Mutant keep_hub: em_wcs_f's copy of the hub value left live.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec exit_mem.c -o exit_mem.O1.ll */
#include "CQ.h"
unsigned em_T[8] = {3, 9, 0, 7, 60, 2, 5, 1};
unsigned em_S[8];

/* (i, iv) a load through a quantum index; exits with a constant per exit */
__attribute__((noinline)) static int em_load_f(unsigned i, unsigned n) {
  while (n) {
    unsigned v = em_T[i & 7];
    if (v == 0) return -1;
    if (v > 50) return 50;
    i += v;
    n = n > v ? n - v : 0;
  }
  return 7;
}
int em_load(unsigned x0, double th, unsigned n) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(em_load_f(x, n & 7));
}

/* (ii, v) a store of a quantum value per trip at a classical index; the exit value a trip value */
__attribute__((noinline)) static int em_store_f(unsigned x) {
  unsigned k = 0;
  while (x) {
    em_S[k & 7] = x;
    k++;
    if ((x & 3) == 3) return (int)(x * 3);
    x >>= 2;
  }
  return -(int)k;
}
int em_store(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int r = em_store_f(x & 0xff);
  return cq_measure(r) * 16 + cq_measure(em_S[1] & 15);
}

/* (iii, iv, v) the sa_wcs shape: *ws walked per trip through a pointer in memory, *s++ stored, an exit arm that stores
 * (*s = 0; *ws = 0) and returns a trip value, an exit returning -1, the classical skip n == 0 */
__attribute__((noinline)) static unsigned em_put(char *s, unsigned c) {
  if (c < 0x80) { *s = (char)c; return 1; }
  if (c < 0x800) { s[0] = (char)(0xc0 | (c >> 6)); s[1] = (char)(0x80 | (c & 0x3f)); return 2; }
  return (unsigned)-1;
}
__attribute__((noinline)) static unsigned em_wcs_f(char *s, const unsigned **ws, unsigned n) {
  unsigned N = n, l;
  while (n) {
    if (**ws - 1u >= 0x7fu) {
      if (!**ws) { *s = 0; *ws = 0; return N - n; }
      l = em_put(s, **ws);
      if (l == (unsigned)-1) return (unsigned)-1;
      s += l; n -= l;
    } else {
      *s++ = (char)**ws; n--;
    }
    (*ws)++;
  }
  return N;
}
unsigned em_wcs(unsigned c0, double th, unsigned n) {
  char out[16] = {0};
  unsigned w[8] = {0x41, 0x100, 0x42, 0x43, 0x44, 0x45, 0, 0};
  w[1] = c0; cq_theta(&w[1], th);
  const unsigned *p = w;
  unsigned r = em_wcs_f(out, &p, n & 7);
  return cq_measure(r) * 4096 + cq_measure((unsigned char)out[1]) * 16 + cq_measure(p ? (unsigned)(p - w) : 15u);
}

/* (iii, iv) *p++ over a local pointer; the return value is a constant per exit joined with the classical skip */
__attribute__((noinline)) static int em_const_f(const unsigned *p, unsigned n) {
  if (n == 0) return 9;
  for (;;) {
    unsigned c = *p++;
    if (c == 0) return -1;
    if (c > 0x80) return 2;
    if (--n == 0) return 3;
    if (c & 1) n++;
  }
}
int em_const(unsigned c0, double th, unsigned n) {
  unsigned w[8] = {0x41, 0x100, 0x42, 0x43, 0, 0x45, 0, 0};
  w[1] = c0; cq_theta(&w[1], th);
  return cq_measure(em_const_f(w, n & 7));
}

/* (iv) the exit values constants (-1, N) and the continuation phi joined with the classical skip n == 0 and returned
 * (cause 2; tsv.c r_b) */
__attribute__((noinline)) static unsigned em_ret_f(char *s, const unsigned **ws, unsigned n) {
  unsigned N = n, l;
  while (n) {
    if (**ws - 1u >= 0x7fu) {
      l = em_put(s, **ws);
      if (l == (unsigned)-1) return (unsigned)-1;
      s += l; n -= l;
    } else {
      *s++ = (char)**ws; n--;
    }
    (*ws)++;
  }
  return N;
}
unsigned em_ret(unsigned c0, double th, unsigned n) {
  char out[16] = {0};
  unsigned w[8] = {0x41, 0x100, 0x42, 0x43, 0x44, 0x45, 0, 0};
  w[1] = c0; cq_theta(&w[1], th);
  const unsigned *p = w;
  unsigned r = em_ret_f(out, &p, n & 7);
  return cq_measure(r) * 4096 + cq_measure((unsigned char)out[1]) * 16 + cq_measure((unsigned)(p - w));
}

/* (vi) an exit inside a classical branch (mode) */
__attribute__((noinline)) static int em_cbr_f(const unsigned *p, unsigned n, int mode) {
  unsigned N = n;
  while (n) {
    unsigned c = *p++;
    if (mode) {
      if (c == 0) return -1;
    }
    if (c > 0x80) return (int)(N - n);
    n = c > n ? 0 : n - c;
  }
  return (int)N;
}
int em_cbr(unsigned c0, double th, unsigned n, int mode) {
  unsigned w[8] = {1, 2, 0, 1, 0x90, 1, 0, 0};
  w[1] = c0 & 0xff; cq_theta(&w[1], th);
  return cq_measure(em_cbr_f(w, n & 7, mode & 1));
}

/* (vii) the region form: the test at the top reads memory, an exit from the body */
__attribute__((noinline)) static int em_top_f(unsigned i, unsigned n) {
  unsigned s = 0;
  while (em_T[i & 7] < 50) {
    if (em_T[i & 7] == 0) return -1;
    s += em_T[i & 7];
    i += 3;
    if (s > n) return (int)s;
  }
  return (int)(s + 100);
}
int em_top(unsigned x0, double th, unsigned n) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(em_top_f(x, n & 31));
}

/* (viii) the sa_wcs shape in a callee clone reached under a quantum predicate */
int em_tail(unsigned c0, double th, unsigned n) {
  char out[16] = {0};
  unsigned w[8] = {0x41, 0x100, 0x42, 0x43, 0, 0x45, 0, 0};
  w[1] = c0; cq_theta(&w[1], th);
  const unsigned *p = w;
  unsigned r = 5;
  if (w[1] & 2)
    r = em_wcs_f(out, &p, n & 7);
  return cq_measure(r) * 16 + cq_measure((unsigned char)out[1]);
}
