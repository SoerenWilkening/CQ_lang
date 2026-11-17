/* sample_rt.c: runtime half of sample_check.py (tooling, not spec).
 * -DSC_LOWERED: sc_call() forwards every cqrt_* / cq_template_* call (through the IR stubs sample_check.py generates) to
 *   the Python evaluator over two pipes (SC_WFD, SC_RFD) and returns its reply; the evaluator may first ask for host
 *   memory ("M addr len", for QROM tables).
 * otherwise: the classical reference for base.O1.ll: cq_theta = identity, cq_measure = identity, both logged with
 *   cq_phi; angles inside __cq_invert_begin/end are logged negated.
 * Both: sc_out_*() print the driver's return values. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
typedef unsigned __int128 u128;
typedef unsigned long long u64;
static FILE *W, *R;
static void sc_init(void) {
  if (W) return;
  const char *w = getenv("SC_WFD"), *r = getenv("SC_RFD");
  if (!w) { fprintf(stderr, "SC_WFD unset\n"); _exit(96); }
  W = fdopen(atoi(w), "w");
  if (r) R = fdopen(atoi(r), "r");
}
static void hex(const void *p, int n) { for (int i = n - 1; i >= 0; i--) fprintf(W, "%02x", ((const unsigned char *)p)[i]); }
void sc_out_i(long long v) { sc_init(); fprintf(W, "O I %llx\n", (u64)v); fflush(W); }
void sc_out_d(double v) { sc_init(); fprintf(W, "O D "); hex(&v, 8); fputc('\n', W); fflush(W); }
void sc_out_f(float v) { sc_init(); fprintf(W, "O F "); hex(&v, 4); fputc('\n', W); fflush(W); }
void sc_out_ld(long double v) { sc_init(); fprintf(W, "O L "); hex(&v, 10); fputc('\n', W); fflush(W); }

#ifdef SC_LOWERED
void sc_call(const char *name, const char *types, int n, const u128 *a, u128 *ret) {
  static char line[1 << 16];
  sc_init();
  fprintf(W, "C %s %s", name, *types ? types : "-");
  for (int i = 0; i < n; i++) fprintf(W, " %llx:%llx", (u64)(a[i] >> 64), (u64)a[i]);
  fputc('\n', W); fflush(W);
  for (;;) {
    if (!fgets(line, sizeof line, R)) _exit(97);
    if (line[0] == 'R') { u64 hi, lo; sscanf(line + 2, "%llx:%llx", &hi, &lo); *ret = ((u128)hi << 64) | lo; return; }
    if (line[0] == 'M') {
      u64 ad, len; sscanf(line + 2, "%llx %llx", &ad, &len);
      fprintf(W, "D ");
      for (u64 k = 0; k < len; k++) fprintf(W, "%02x", ((const unsigned char *)ad)[k]);
      fputc('\n', W); fflush(W); continue;
    }
    _exit(98);   /* 'X': the evaluator gave up on this run */
  }
}
#else
static int inv;
static void rot(const char *k, double a) { sc_init(); if (inv & 1) a = -a; fprintf(W, "E %s ", k); hex(&a, 8); fputc('\n', W); fflush(W); }
#define TH(S, T) T cq_theta_##S(T x, double a) { rot("RY", a); return x; }
#define ME(S, T, B, N) T cq_measure_##S(T x) { sc_init(); fprintf(W, "E M %d ", B); hex(&x, N); fputc('\n', W); fflush(W); return x; }
TH(i1, bool) TH(c, char) TH(si8, signed char) TH(ui8, unsigned char) TH(si16, short) TH(ui16, unsigned short)
TH(si32, int) TH(ui32, unsigned) TH(sl, long) TH(ul, unsigned long) TH(sll, long long) TH(ull, unsigned long long)
TH(f32, float) TH(f64, double) TH(f80, long double)
ME(i1, bool, 1, 1) ME(c, char, 8, 1) ME(si8, signed char, 8, 1) ME(ui8, unsigned char, 8, 1) ME(si16, short, 16, 2)
ME(ui16, unsigned short, 16, 2) ME(si32, int, 32, 4) ME(ui32, unsigned, 32, 4) ME(sl, long, 64, 8) ME(ul, unsigned long, 64, 8)
ME(sll, long long, 64, 8) ME(ull, unsigned long long, 64, 8) ME(f32, float, 32, 4) ME(f64, double, 64, 8) ME(f80, long double, 80, 10)
void cq_phi(double a) { rot("PH", a); }
void __cq_invert_begin(void) { inv++; }
void __cq_invert_end(void) { inv--; }
#endif
