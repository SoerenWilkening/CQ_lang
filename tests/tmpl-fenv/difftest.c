/* tmpl-fenv differential test (cq-w0-tmpl-fenv acceptance).
 *
 * For every op this family claims, at f16/f32/f64 and the integer widths i1 i7 i8 i16 i32 i64
 * i100 i128, on edge values, fp specials and a seeded random set, under all four rounding modes
 * (as _rm, as _rmq with garbage in the ignored mode bits, and without a mode = nearest-even),
 * the value form and the _exc form are evaluated through the registry (mock_core.c) and compared
 * bit for bit with:
 *   - native: the same LLVM operation compiled by clang-19 -O1 under FENV_ACCESS (native.c) and
 *     run on the host (f32/f64, integers up to 64 bits);
 *   - reference, where native x86-64 code is not IEEE under a rounding mode: f16 (the host
 *     emulates half through f32 and RNE-only libcalls) and integers wider than 64 bits
 *     (compiler-rt libcalls ignore the mode and raise nothing). The reference computes the op in
 *     f64 natively under round-toward-zero, makes it round-to-odd, and rounds that to the target
 *     with rint under the target mode (correct for every p <= 51); wide integers are rounded with
 *     __int128 arithmetic;
 *   - table, where CR §2 / §1.2 differ from the native libm (frem invalid cases: libm fmod(x, 0)
 *     raises nothing and returns +NaN; CR: invalid arithmetic raises INVALID and gives the
 *     default NaN), stated per case below.
 *   - native-nonstrict (CR §2 at CQ_spec e46f5e3, cq-e3t): the VALUE CR adopts from LLVM 19's
 *     inline ExpandLargeFpConvert for sitofp/uitofp from i129, i200, i1100 (native_ns.c, no
 *     FENV_ACCESS: LLVM 19 cannot compile the strict form), run under the mode; f16 and bf16 as
 *     its f32 then the reference (IEEE, in the mode) fptrunc. sitofp/uitofp to bf16 from <= 128
 *     bits: f32 in the mode (native cvtsi2ss up to 64 bits), then that IEEE fptrunc. The _exc bits
 *     stay IEEE in the mode (reference).
 * Also: every claimed op declines (CQE_OP_NOT_MINE) its plain form and every f80 form; fcmps is
 * claimed in every form. Exit status 0 iff no mismatch; counts are printed per op and width.
 *
 * Size: quick by default (cq-m4s9): every edge tuple, form, mode and check above, 200 random
 * samples per op and width (50 for the wide sitofp/uitofp sources). CQ_FULL=1 (any value but
 * empty or "0") restores the full 4000 (1000). An explicit count on the command line wins. */
#include <fenv.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

int mock_dispatch(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out);
int mock_registered(const char *op);
extern int mock_fail_count;

int nat_bin_f32(int op, const void *a, const void *b, int mode, void *r);
int nat_bin_f64(int op, const void *a, const void *b, int mode, void *r);
int nat_fma_f32(const void *a, const void *b, const void *c, int mode, void *r);
int nat_fma_f64(const void *a, const void *b, const void *c, int mode, void *r);
int nat_un_f32(int op, const void *a, int mode, void *r);
int nat_un_f64(int op, const void *a, int mode, void *r);
int nat_cmp_f32(int k, const void *a, const void *b, int *res);
int nat_cmp_f64(int k, const void *a, const void *b, int *res);
int nat_toint_f32(int N, int sgn, const void *a, int mode);
int nat_toint_f64(int N, int sgn, const void *a, int mode);
int nat_itofp_f32(int N, int sgn, uint64_t v, int mode, void *r);
int nat_itofp_f64(int N, int sgn, uint64_t v, int mode, void *r);
int nat_fpconv(int from, int to, const void *a, int mode, void *r);
int nat_f64_op(int op, double a, double b, double c, int mode, double *r);
double nat_rint_mode(double x, int mode);
int nat_cmp2_f64(int signaling, double a, double b, int *res);
/* native_ns.c: non-strict code, the value CR §2 adopts (the caller sets the mode) */
uint64_t ns_wide(int N, int sgn, int to, const uint64_t *w);
static uint64_t ns_wide_m(int N, int sgn, int to, const uint64_t *w, int mode) {
  fesetround(mode);
  uint64_t r = ns_wide(N, sgn, to, w);
  fesetround(FE_TONEAREST);
  return r;
}

enum { N_ADD, N_SUB, N_MUL, N_DIV, N_REM, N_MAX, N_MIN };
enum { U_SQRT, U_FLOOR, U_CEIL, U_TRUNC, U_ROUND, U_RINT };
enum { Q_LT, Q_LE, Q_GT, Q_GE, Q_EQ, Q_NE, Q_UN, Q_LG, S_LT, S_LE, S_GT, S_GE };
enum { X_INVALID = 1, X_DIVBYZERO = 4, X_OVERFLOW = 8, X_UNDERFLOW = 16, X_INEXACT = 32 };

static const int MODES[4] = {0x000, 0x400, 0x800, 0xC00};

/* ------------------------------------------------------------------------------------------- */
static uint64_t rs = 0x5EED0F7E1C0FFEEull;
static uint64_t rnd(void) { /* splitmix64 */
  uint64_t z = (rs += 0x9E3779B97F4A7C15ull);
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
  return z ^ (z >> 31);
}

typedef struct { uint64_t w[2]; } v128;

/* ------------------------------------------------------------------------------------------- */
/* Calling the family through the registry. */

typedef struct {
  const char *op, *pred, *w, *to;
  int rm, exc;
} form_t;

static long n_cases, n_bad;
static int print_budget = 100000;

/* returns rc; *res gets the out value (two words) */
static int call_mine(const form_t *f, const v128 *argv, const int *argbits, int nargs, int mode,
                     int resbits, v128 *res) {
  cqe_tname t;
  memset(&t, 0, sizeof t);
  snprintf(t.op, sizeof t.op, "%s", f->op);
  snprintf(t.pred, sizeof t.pred, "%s", f->pred ? f->pred : "");
  snprintf(t.w, sizeof t.w, "%s", f->w);
  snprintf(t.to, sizeof t.to, "%s", f->to ? f->to : "");
  t.rm = (uint8_t)f->rm;
  t.exc = (uint8_t)f->exc;
  cqe_val a[4];
  uint64_t store[4][2];
  for (int i = 0; i < nargs; ++i) {
    store[i][0] = argv[i].w[0];
    store[i][1] = argv[i].w[1];
    a[i].bits = (uint32_t)argbits[i];
    a[i].kind = 'f';
    a[i].nw = (uint32_t)((argbits[i] + 63) / 64);
    a[i].w = store[i];
  }
  int n = nargs;
  uint64_t mstore[1];
  if (f->rm) {
    uint64_t m = (uint64_t)(uint32_t)mode;
    if (f->rm == 2) /* a rail: garbage in every ignored bit */
      m |= (rnd() & 0xFFFFF3FFull);
    mstore[0] = m & 0xFFFFFFFFull;
    a[n].bits = 32;
    a[n].kind = 'i';
    a[n].nw = 1;
    a[n].w = mstore;
    n++;
  }
  uint64_t ow[2] = {0, 0};
  cqe_val out = {(uint32_t)resbits, 'i', (uint32_t)((resbits + 63) / 64), ow};
  int rc = mock_dispatch(&t, a, n, &out);
  res->w[0] = ow[0];
  res->w[1] = ow[1];
  return rc;
}

static const char *MODENAME[4] = {"ne", "dn", "up", "tz"};

static void report(const form_t *f, int mi, const v128 *argv, int nargs, const char *what,
                   const v128 *got, const v128 *want, const char *src) {
  n_bad++;
  if (print_budget-- <= 0)
    return;
  printf("MISMATCH %s%s%s %s%s%s rm=%d exc=%d mode=%s [%s] args:", f->op, f->pred ? "_" : "",
         f->pred ? f->pred : "", f->w, f->to ? "_to_" : "", f->to ? f->to : "", f->rm, f->exc,
         MODENAME[mi], src);
  for (int i = 0; i < nargs; ++i)
    printf(" %llx:%016llx", (unsigned long long)argv[i].w[1], (unsigned long long)argv[i].w[0]);
  printf(" %s got %llx:%016llx want %llx:%016llx\n", what, (unsigned long long)got->w[1],
         (unsigned long long)got->w[0], (unsigned long long)want->w[1],
         (unsigned long long)want->w[0]);
}

/* Evaluate the value and exc forms over every mode variant and compare with the expected
 * (value, flags) per mode. has_value: the op has a value form under _rm (otherwise only _exc,
 * with no mode argument). */
typedef struct {
  v128 val;
  int fl;
} expect_t;

static void check_forms(const char *op, const char *pred, const char *w, const char *to,
                        int has_rm, const v128 *argv, const int *argbits, int nargs, int valbits,
                        const expect_t exp[4], const char *src) {
  for (int rm = 0; rm <= (has_rm ? 2 : 0); ++rm)
    for (int exc = 0; exc <= 1; ++exc) {
      if (!exc && !has_rm && strcmp(op, "fcmps"))
        continue; /* no value form under fenv */
      if (!exc && rm == 0 && strcmp(op, "fcmps"))
        continue; /* the plain form is another family's */
      for (int mi = 0; mi < 4; ++mi) {
        if (rm == 0 && mi != 0)
          continue;
        form_t f = {op, pred, w, to, rm, exc};
        v128 got;
        int rb = exc ? 32 : valbits;
        int rc = call_mine(&f, argv, argbits, nargs, MODES[mi], rb, &got);
        n_cases++;
        v128 want = exp[mi].val;
        if (exc) {
          want.w[0] = (uint64_t)exp[mi].fl;
          want.w[1] = 0;
        }
        if (rc != 0) {
          v128 z = {{(uint64_t)rc, 0}};
          report(&f, mi, argv, nargs, "rc", &z, &want, src);
        } else if (got.w[0] != want.w[0] || got.w[1] != want.w[1]) {
          report(&f, mi, argv, nargs, exc ? "exc" : "value", &got, &want, src);
        }
      }
    }
}

/* ------------------------------------------------------------------------------------------- */
/* Formats and inputs. */

typedef struct {
  const char *name;
  int W, eb, fb;
} fmt_t;
static const fmt_t F16 = {"f16", 16, 5, 10}, BF16 = {"bf16", 16, 8, 7}, F32 = {"f32", 32, 8, 23}, F64 = {"f64", 64, 11, 52};

static uint64_t mk(const fmt_t *f, int s, uint64_t be, uint64_t frac) {
  return ((uint64_t)s << (f->W - 1)) | (be << f->fb) | (frac & ((1ull << f->fb) - 1));
}
static int edges(const fmt_t *f, uint64_t *o) {
  int n = 0;
  uint64_t emax = (1ull << f->eb) - 1, fm = (1ull << f->fb) - 1, q = 1ull << (f->fb - 1);
  uint64_t bias = (emax >> 1);
  for (int s = 0; s < 2; ++s) {
    o[n++] = mk(f, s, 0, 0);                /* 0 */
    o[n++] = mk(f, s, 0, 1);                /* min subnormal */
    o[n++] = mk(f, s, 0, fm);               /* max subnormal */
    o[n++] = mk(f, s, 1, 0);                /* min normal */
    o[n++] = mk(f, s, 1, 1);
    o[n++] = mk(f, s, emax - 1, fm);        /* max finite */
    o[n++] = mk(f, s, emax - 1, fm - 1);
    o[n++] = mk(f, s, bias, 0);             /* 1 */
    o[n++] = mk(f, s, bias, 1);             /* 1 + ulp */
    o[n++] = mk(f, s, bias - 1, fm);        /* 1 - ulp/2 */
    o[n++] = mk(f, s, bias + 1, q);         /* 3 */
    o[n++] = mk(f, s, bias - 1, 0);         /* 0.5 */
    o[n++] = mk(f, s, bias + f->fb, 1);     /* 2^p + 2 */
    o[n++] = mk(f, s, emax, 0);             /* inf */
    o[n++] = mk(f, s, emax, q);             /* default-pattern qNaN */
    o[n++] = mk(f, s, emax, q | 5);         /* qNaN, payload */
    o[n++] = mk(f, s, emax, 1);             /* sNaN */
    o[n++] = mk(f, s, emax, q - 1);         /* sNaN, full payload */
  }
  if (f->W == 32) { /* NaNs at the bf16 truncation boundary: low 16 fraction bits zero or not */
    o[n++] = 0x7fa00000;
    o[n++] = 0x7fa00001;
    o[n++] = 0xff810000;
    o[n++] = 0x7f800001;
  }
  /* integral boundaries for conversions */
  int64_t ints[] = {127, 128, -128, -129, 255, 256, 32767, 32768, -32769, 65535, 65536};
  for (size_t i = 0; i < sizeof ints / sizeof ints[0]; ++i) {
    double d = (double)ints[i];
    int e;
    double m = frexp(fabs(d), &e);
    uint64_t be = (uint64_t)(e - 1) + bias;
    if (be >= emax)
      continue;
    uint64_t fr = (uint64_t)ldexp(m * 2 - 1, f->fb);
    o[n++] = mk(f, d < 0, be, fr);
  }
  for (int k = 0; k < 2; ++k) /* 2^31, 2^63, 2^64 and neighbours */
    for (int e2 = 31; e2 <= 64; e2 += (e2 == 31 ? 32 : 1)) {
      uint64_t be = (uint64_t)e2 + bias;
      if (be >= emax)
        continue;
      o[n++] = mk(f, k, be, 0);
      o[n++] = mk(f, k, be - 1, fm);
    }
  return n;
}
static uint64_t rand_val(const fmt_t *f) {
  uint64_t emax = (1ull << f->eb) - 1, bias = emax >> 1, fm = (1ull << f->fb) - 1;
  int s = (int)(rnd() & 1);
  uint64_t be, fr;
  switch (rnd() % 6) {
  case 0: return rnd() & ((f->W == 64) ? ~0ull : ((1ull << f->W) - 1)); /* raw bits */
  case 1: be = bias - (f->fb + 2) + rnd() % (2 * f->fb + 4); break;    /* near 1 */
  case 2: be = rnd() % (f->fb + 3); break;                                /* near/below min */
  case 3: be = emax - 1 - rnd() % (f->fb + 2); break;                      /* near max */
  case 4: be = 1 + rnd() % (emax - 1); break;                              /* any normal */
  default: be = bias + rnd() % 70; break;                                  /* integer range */
  }
  switch (rnd() % 4) {
  case 0: fr = rnd() & fm; break;
  case 1: fr = (rnd() & fm) & ~((1ull << (rnd() % (f->fb + 1))) - 1); break; /* few low bits */
  case 2: fr = fm; break;
  default: fr = (rnd() & fm) >> (rnd() % (f->fb + 1)); break;
  }
  if (be >= emax)
    be = emax - 1;
  return mk(f, s, be, fr);
}

/* ------------------------------------------------------------------------------------------- */
/* f16 reference. */

static int small(const fmt_t *f) { return f->W == 16; } /* f16, bf16: reference path */
static int sbias(const fmt_t *f) { return (1 << (f->eb - 1)) - 1; }
/* exact decode of a 16-bit format to double; a NaN keeps sign, quiet bit and payload */
static double decs(const fmt_t *f, uint64_t h) {
  int s = (int)(h >> 15) & 1, em = (1 << f->eb) - 1, e = (int)(h >> f->fb) & em;
  uint64_t fr = h & ((1ull << f->fb) - 1);
  if (e == em) {
    uint64_t b = ((uint64_t)s << 63) | (0x7FFull << 52) | (fr << (52 - f->fb));
    double d;
    memcpy(&d, &b, 8);
    return d;
  }
  int emin = 1 - sbias(f);
  double v = e ? ldexp((double)((1ull << f->fb) + fr), e - sbias(f) - f->fb)
               : ldexp((double)fr, emin - f->fb);
  return s ? -v : v;
}
/* r is representable in f, Inf or NaN (NaN: payload truncated, quieted) */
static uint64_t encs(const fmt_t *f, double r) {
  uint64_t b;
  memcpy(&b, &r, 8);
  uint64_t s = (b >> 63) << 15, em = (1ull << f->eb) - 1, q = 1ull << (f->fb - 1);
  if (isnan(r))
    return s | (em << f->fb) | ((b & ((1ull << 52) - 1)) >> (52 - f->fb)) | q;
  if (isinf(r))
    return s | (em << f->fb);
  if (r == 0)
    return s;
  double a = fabs(r);
  int e, emin = 1 - sbias(f);
  frexp(a, &e);
  int lead = e - 1;
  if (lead >= emin) {
    uint64_t m = (uint64_t)ldexp(a, f->fb - lead);
    return s | ((uint64_t)(lead + sbias(f)) << f->fb) | (m - (1ull << f->fb));
  }
  return s | (uint64_t)ldexp(a, f->fb - emin);
}
/* round x (finite, nonzero, possibly round-to-odd) to precision p, exponent range [emin, emax],
 * under mode; returns the rounded double (or +-Inf / +-max) and adds flags */
static double ref_round(double x, int p, int emin, int emax, int mode, int *fl) {
  if (x == 0 || isnan(x) || isinf(x))
    return x;
  int e;
  frexp(x, &e);
  int lead = e - 1;
  int qu = lead - p + 1;
  double ru = ldexp(nat_rint_mode(ldexp(x, -qu), mode), qu);
  int tiny = fabs(ru) < ldexp(1, emin);
  int q = (lead > emin ? lead : emin) - p + 1;
  double r = ldexp(nat_rint_mode(ldexp(x, -q), mode), q);
  double maxf = ldexp(ldexp(1, p) - 1, emax - p + 1);
  if (fabs(r) > maxf) {
    *fl |= X_OVERFLOW | X_INEXACT;
    int neg = x < 0;
    int toinf = mode == 0 || (mode == 0x800 && !neg) || (mode == 0x400 && neg);
    return toinf ? (neg ? -INFINITY : INFINITY) : (neg ? -maxf : maxf);
  }
  if (r != x) {
    *fl |= X_INEXACT;
    if (tiny)
      *fl |= X_UNDERFLOW;
  }
  return r;
}
static double to_odd(double rz, int inexact) {
  if (!inexact || isnan(rz) || isinf(rz) || rz == 0)
    return rz;
  uint64_t b;
  memcpy(&b, &rz, 8);
  b |= 1;
  memcpy(&rz, &b, 8);
  return rz;
}
/* f16 result of f64 op `op` on decoded operands, under mode */
static expect_t refs_op(const fmt_t *f, int op, double a, double b, double c, int mode) {
  double rm_, rz;
  int flm = nat_f64_op(op, a, b, c, mode, &rm_);
  int flz = nat_f64_op(op, a, b, c, 0xC00, &rz);
  expect_t e;
  e.fl = flm & (X_INVALID | X_DIVBYZERO);
  double r;
  if (op >= 7) { /* roundToIntegral, fmax, fmin: exact in f16, the native f64 op decides */
    e.fl = flm;
    r = rm_;
  } else if (isnan(rm_) || isinf(rm_) || rm_ == 0)
    r = rm_; /* NaN, Inf (division by zero) and exact zeros from the real mode */
  else
    r = ref_round(to_odd(rz, flz & X_INEXACT), f->fb + 1, 1 - sbias(f), sbias(f), mode, &e.fl);
  e.val.w[0] = encs(f, r);
  e.val.w[1] = 0;
  return e;
}

/* ------------------------------------------------------------------------------------------- */
/* Per-op drivers. */

static int is_nan_bits(const fmt_t *f, uint64_t b) {
  uint64_t emax = (1ull << f->eb) - 1;
  return ((b >> f->fb) & emax) == emax && (b & ((1ull << f->fb) - 1));
}
static int is_snan_bits(const fmt_t *f, uint64_t b) {
  return is_nan_bits(f, b) && !((b >> (f->fb - 1)) & 1);
}
static uint64_t quiet(const fmt_t *f, uint64_t b) { return b | (1ull << (f->fb - 1)); }
static uint64_t default_nan(const fmt_t *f) {
  return mk(f, 1, (1ull << f->eb) - 1, 1ull << (f->fb - 1));
}

static const char *BIN_OPS[] = {"fadd", "fsub", "fmul", "fdiv", "frem", "fmax", "fmin"};

/* the CR table for frem's specials, or 0 if the case is not special */
static int frem_table(const fmt_t *f, uint64_t a, uint64_t b, expect_t *e) {
  uint64_t emax = (1ull << f->eb) - 1, mag = (1ull << (f->W - 1)) - 1;
  int an = is_nan_bits(f, a), bnn = is_nan_bits(f, b);
  e->val.w[1] = 0;
  if (an || bnn) {
    e->fl = (is_snan_bits(f, a) || is_snan_bits(f, b)) ? X_INVALID : 0;
    e->val.w[0] = quiet(f, an ? a : b);
    return 1;
  }
  int ainf = (a & mag) == (emax << f->fb), bzero = (b & mag) == 0;
  if (ainf || bzero) {
    e->fl = X_INVALID;
    e->val.w[0] = default_nan(f);
    return 1;
  }
  return 0;
}

static void test_binary(const fmt_t *f, const uint64_t *xs, int nx, int nrand) {
  for (int oi = 0; oi < 7; ++oi) {
    long c0 = n_cases, b0 = n_bad;
    int has_rm = oi <= N_REM;
    for (int it = 0; it < nx * nx + nrand; ++it) {
      uint64_t a, b;
      if (it < nx * nx) {
        a = xs[it / nx];
        b = xs[it % nx];
      } else {
        a = rand_val(f);
        b = rand_val(f);
        if (rnd() % 3 == 0) { /* close exponents: cancellation, ties */
          uint64_t em = (1ull << f->eb) - 1;
          uint64_t ea = (a >> f->fb) & em;
          uint64_t eb = ea + (rnd() % 5) - 2;
          if (eb >= em || eb == 0 || ea == em)
            eb = ea;
          b = (b & ~(em << f->fb)) | (eb << f->fb);
        } else if (rnd() % 3 == 0 && oi == N_MUL) { /* products near the underflow boundary */
          uint64_t em = (1ull << f->eb) - 1, bias = em >> 1;
          uint64_t ea = 1 + rnd() % (em - 2);
          int64_t ebs = (int64_t)bias + 1 - ((int64_t)ea - (int64_t)bias) - (int64_t)(rnd() % 3);
          if (ebs < 1)
            ebs = 1;
          if (ebs >= (int64_t)em)
            ebs = (int64_t)em - 1;
          a = (a & ~(em << f->fb)) | (ea << f->fb);
          b = (b & ~(em << f->fb)) | ((uint64_t)ebs << f->fb);
        }
      }
      v128 av[2] = {{{a, 0}}, {{b, 0}}};
      int ab[2] = {f->W, f->W};
      expect_t ex[4];
      const char *src = "native";
      for (int mi = 0; mi < 4; ++mi) {
        int md = MODES[mi];
        if (oi == N_REM && frem_table(f, a, b, &ex[mi])) {
          src = "table";
          continue;
        }
        if (oi >= N_MAX && is_nan_bits(f, a) && is_nan_bits(f, b)) {
          /* table: two NaN operands. macOS libm fmax(qNaN, sNaN) raises nothing; IEEE 754
           * maxNum/minNum and CR §1.2 (a signaling NaN operand is invalid) raise INVALID */
          src = "table";
          ex[mi].val.w[0] = ex[mi].val.w[1] = 0;
          ex[mi].fl = (is_snan_bits(f, a) || is_snan_bits(f, b)) ? X_INVALID : 0;
          continue;
        }
        if (small(f)) {
          src = "reference";
          static const int map[] = {0, 1, 2, 3, 6, 12, 13};
          ex[mi] = refs_op(f, map[oi], decs(f, a), decs(f, b), 0, md);
          if (oi >= N_MAX) { /* fmax/fmin: exc only (value per CR, not compared here) */
            ex[mi].val.w[0] = 0;
          }
          continue;
        }
        uint64_t r = 0;
        ex[mi].fl = (f->W == 32 ? nat_bin_f32 : nat_bin_f64)(oi, &a, &b, md, &r);
        ex[mi].val.w[0] = f->W == 32 ? (r & 0xFFFFFFFFull) : r;
        ex[mi].val.w[1] = 0;
      }
      check_forms(BIN_OPS[oi], NULL, f->name, NULL, has_rm, av, ab, 2, f->W, ex, src);
    }
    printf("  %-8s %-4s cases %8ld mismatches %ld\n", BIN_OPS[oi], f->name, n_cases - c0,
           n_bad - b0);
  }
}

static void test_fma(const fmt_t *f, const uint64_t *xs, int nx, int nrand) {
  long c0 = n_cases, b0 = n_bad;
  int step = nx > 24 ? 2 : 1;
  for (int it = 0;; ++it) {
    uint64_t a, b, c;
    int ne = 0;
    for (int i = 0; i < nx; i += step)
      ne++;
    long nedge = (long)ne * ne * ne;
    if (it >= nedge + nrand)
      break;
    if (it < nedge) {
      a = xs[(it / (ne * ne)) * step];
      b = xs[((it / ne) % ne) * step];
      c = xs[(it % ne) * step];
    } else {
      a = rand_val(f);
      b = rand_val(f);
      c = rand_val(f);
    }
    v128 av[3] = {{{a, 0}}, {{b, 0}}, {{c, 0}}};
    int ab[3] = {f->W, f->W, f->W};
    expect_t ex[4];
    const char *src = small(f) ? "reference" : "native";
    int nn = is_nan_bits(f, a) + is_nan_bits(f, b) + is_nan_bits(f, c);
    for (int mi = 0; mi < 4; ++mi) {
      if (nn >= 2) {
        /* table: CR §2 NaN row, normative over libm (ruling 2026-10-27): the first NaN operand
         * in IR order, quieted; INVALID iff a signaling NaN (both agree with libm) */
        src = "table";
        uint64_t first = is_nan_bits(f, a) ? a : is_nan_bits(f, b) ? b : c;
        ex[mi].val.w[0] = quiet(f, first);
        ex[mi].val.w[1] = 0;
        ex[mi].fl = (is_snan_bits(f, a) || is_snan_bits(f, b) || is_snan_bits(f, c)) ? X_INVALID : 0;
        continue;
      }
      if (small(f)) {
        ex[mi] = refs_op(f, 4, decs(f, a), decs(f, b), decs(f, c), MODES[mi]);
        continue;
      }
      uint64_t r = 0;
      ex[mi].fl = (f->W == 32 ? nat_fma_f32 : nat_fma_f64)(&a, &b, &c, MODES[mi], &r);
      ex[mi].val.w[0] = f->W == 32 ? (r & 0xFFFFFFFFull) : r;
      ex[mi].val.w[1] = 0;
    }
    check_forms("fma", NULL, f->name, NULL, 1, av, ab, 3, f->W, ex, src);
  }
  printf("  %-8s %-4s cases %8ld mismatches %ld\n", "fma", f->name, n_cases - c0, n_bad - b0);
}

static const char *UN_OPS[] = {"sqrt", "floor", "ceil", "trunc", "round", "rint"};

static void test_unary(const fmt_t *f, const uint64_t *xs, int nx, int nrand) {
  for (int oi = 0; oi < 6; ++oi) {
    long c0 = n_cases, b0 = n_bad;
    int has_rm = oi == U_SQRT || oi == U_RINT;
    for (int it = 0; it < nx + nrand; ++it) {
      uint64_t a = it < nx ? xs[it] : rand_val(f);
      v128 av[1] = {{{a, 0}}};
      int ab[1] = {f->W};
      expect_t ex[4];
      const char *src = small(f) ? "reference" : "native";
      for (int mi = 0; mi < 4; ++mi) {
        int md = MODES[mi];
        /* rint without a mode argument ties to even whatever the dynamic mode (CR §2): the
         * rm == 0 variant runs at mi == 0 only, which is nearest-even */
        if (small(f)) {
          static const int map[] = {5, 7, 8, 9, 10, 11};
          ex[mi] = refs_op(f, map[oi], decs(f, a), 0, 0, md);
          continue;
        }
        uint64_t r = 0;
        ex[mi].fl = (f->W == 32 ? nat_un_f32 : nat_un_f64)(oi, &a, md, &r);
        ex[mi].val.w[0] = f->W == 32 ? (r & 0xFFFFFFFFull) : r;
        ex[mi].val.w[1] = 0;
      }
      check_forms(UN_OPS[oi], NULL, f->name, NULL, has_rm, av, ab, 1, f->W, ex, src);
    }
    printf("  %-8s %-4s cases %8ld mismatches %ld\n", UN_OPS[oi], f->name, n_cases - c0,
           n_bad - b0);
  }
}

static const char *PREDS[] = {"false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq",
                              "ugt",   "uge", "ult", "ule", "une", "uno", "true"};
static int pred_val(int pi, int lt, int eq, int gt, int un) {
  switch (pi) {
  case 0: return 0;
  case 1: return eq;
  case 2: return gt;
  case 3: return gt || eq;
  case 4: return lt;
  case 5: return lt || eq;
  case 6: return lt || gt;
  case 7: return !un;
  case 8: return un || eq;
  case 9: return un || gt;
  case 10: return un || gt || eq;
  case 11: return un || lt;
  case 12: return un || lt || eq;
  case 13: return un || lt || gt;
  case 14: return un;
  default: return 1;
  }
}

static void test_cmp(const fmt_t *f, const uint64_t *xs, int nx, int nrand) {
  long c0 = n_cases, b0 = n_bad;
  for (int it = 0; it < nx * nx + nrand; ++it) {
    uint64_t a = it < nx * nx ? xs[it / nx] : rand_val(f);
    uint64_t b = it < nx * nx ? xs[it % nx] : (rnd() % 4 == 0 ? a : rand_val(f));
    v128 av[2] = {{{a, 0}}, {{b, 0}}};
    int ab[2] = {f->W, f->W};
    int lt, eq, gt, un, flq, fls;
    const char *src;
    if (small(f)) {
      int r;
      src = "reference";
      flq = nat_cmp2_f64(0, decs(f, a), decs(f, b), &r);
      fls = nat_cmp2_f64(1, decs(f, a), decs(f, b), &r);
      lt = r & 1, eq = (r >> 1) & 1, gt = (r >> 2) & 1, un = (r >> 3) & 1;
    } else {
      int (*cmp)(int, const void *, const void *, int *) = f->W == 32 ? nat_cmp_f32 : nat_cmp_f64;
      src = "native";
      cmp(Q_LT, &a, &b, &lt);
      cmp(Q_GT, &a, &b, &gt);
      cmp(Q_UN, &a, &b, &un);
      flq = cmp(Q_EQ, &a, &b, &eq);
      int dummy;
      fls = cmp(S_LT, &a, &b, &dummy);
      /* the other signaling compares raise the same flags (checked here, not assumed) */
      int f2 = cmp(S_GE, &a, &b, &dummy), f3 = cmp(S_GT, &a, &b, &dummy),
          f4 = cmp(S_LE, &a, &b, &dummy);
      int f5 = cmp(Q_LT, &a, &b, &dummy), f6 = cmp(Q_UN, &a, &b, &dummy);
      if (f2 != fls || f3 != fls || f4 != fls || f5 != flq || f6 != flq) {
        printf("NOTE native compare flags differ by predicate at %llx %llx\n",
               (unsigned long long)a, (unsigned long long)b);
        n_bad++;
      }
    }
    for (int pi = 0; pi < 16; ++pi)
      for (int sig = 0; sig <= 1; ++sig) {
        expect_t ex[4];
        for (int mi = 0; mi < 4; ++mi) {
          ex[mi].val.w[0] = (uint64_t)pred_val(pi, lt, eq, gt, un);
          ex[mi].val.w[1] = 0;
          ex[mi].fl = sig ? fls : flq;
        }
        check_forms(sig ? "fcmps" : "fcmp", PREDS[pi], f->name, NULL, 0, av, ab, 2, 1, ex, src);
      }
  }
  printf("  %-8s %-4s cases %8ld mismatches %ld\n", "fcmp(s)", f->name, n_cases - c0, n_bad - b0);
}

/* fptrunc / fpext among f16 f32 f64 */
static void test_fpconv(const fmt_t *from, const fmt_t *to, const uint64_t *xs, int nx,
                        int nrand) {
  long c0 = n_cases, b0 = n_bad;
  int trunc_ = to->W < from->W;
  for (int it = 0; it < nx + nrand; ++it) {
    uint64_t a = it < nx ? xs[it] : rand_val(from);
    v128 av[1] = {{{a, 0}}};
    int ab[1] = {from->W};
    expect_t ex[4];
    const char *src = (small(from) || small(to)) ? "reference" : "native";
    for (int mi = 0; mi < 4; ++mi) {
      int md = MODES[mi];
      ex[mi].val.w[1] = 0;
      if (!small(from) && !small(to)) {
        uint64_t r = 0;
        ex[mi].fl = nat_fpconv(from->W, to->W, &a, md, &r);
        ex[mi].val.w[0] = to->W == 32 ? (r & 0xFFFFFFFFull) : r;
        continue;
      }
      /* reference: decode the source exactly to double (a NaN keeps its payload) */
      double x;
      if (small(from))
        x = decs(from, a);
      else if (from->W == 32) {
        float fv;
        uint32_t u = (uint32_t)a;
        memcpy(&fv, &u, 4);
        /* widen without the host (keep sNaN): rebuild the bits */
        if (isnan(fv)) {
          uint64_t b = ((uint64_t)(u >> 31) << 63) | (0x7FFull << 52) |
                       ((uint64_t)(u & 0x7FFFFF) << 29);
          memcpy(&x, &b, 8);
        } else
          x = fv;
      } else
        memcpy(&x, &a, 8);
      ex[mi].fl = is_snan_bits(from, a) ? X_INVALID : 0;
      if (isnan(x)) { /* payload left-aligned, truncated or zero-filled, quieted */
        uint64_t b;
        memcpy(&b, &x, 8);
        uint64_t fr52 = b & ((1ull << 52) - 1);
        uint64_t frt = fr52 >> (52 - to->fb);
        ex[mi].val.w[0] = mk(to, (int)(b >> 63), (1ull << to->eb) - 1, frt | (1ull << (to->fb - 1)));
        continue;
      }
      double r = x;
      if (small(to))
        r = ref_round(x, to->fb + 1, 1 - sbias(to), sbias(to), md, &ex[mi].fl);
      if (small(to))
        ex[mi].val.w[0] = encs(to, r);
      else if (to->W == 32) {
        float fv = (float)r; /* exact: an f16 value */
        uint32_t u;
        memcpy(&u, &fv, 4);
        ex[mi].val.w[0] = u;
      } else {
        uint64_t u;
        memcpy(&u, &r, 8);
        ex[mi].val.w[0] = u;
      }
    }
    check_forms(trunc_ ? "fptrunc" : "fpext", NULL, from->name, to->name, trunc_, av, ab, 1, to->W,
                ex, src);
  }
  printf("  %-8s %s->%s cases %8ld mismatches %ld\n", trunc_ ? "fptrunc" : "fpext", from->name,
         to->name, n_cases - c0, n_bad - b0);
}

/* integer -> fp */
static const int IW[] = {1, 7, 8, 16, 32, 64, 100, 128};

static v128 imask(v128 v, int N) {
  if (N < 64) {
    v.w[0] &= (1ull << N) - 1;
    v.w[1] = 0;
  } else if (N == 64)
    v.w[1] = 0;
  else if (N < 128)
    v.w[1] &= (1ull << (N - 64)) - 1;
  return v;
}
static v128 rand_int(int N) {
  v128 v = {{rnd(), rnd()}};
  switch (rnd() % 3) {
  case 0: break;
  case 1: { /* leading bit at a random position */
    int L = (int)(rnd() % N);
    if (L < 64) {
      v.w[0] &= (L == 63 ? ~0ull : ((2ull << L) - 1));
      v.w[0] |= 1ull << L;
      v.w[1] = 0;
    } else {
      v.w[1] &= (L == 127 ? ~0ull : ((2ull << (L - 64)) - 1));
      v.w[1] |= 1ull << (L - 64);
    }
    break;
  }
  default: { /* ones in the top bits: negative, small magnitude */
    v.w[0] = ~(rnd() >> (rnd() % 64));
    v.w[1] = ~0ull;
    break;
  }
  }
  return imask(v, N);
}
/* reference rounding of an integer magnitude to precision p; returns the value as long double
 * (exact: p <= 64) or overflow handling via emax; flags added */
static long double ref_int_round(unsigned __int128 u, int neg, int p, int emax, int mode,
                                 int *fl) {
  if (u == 0)
    return 0;
  int L = 128 - (u >> 64 ? __builtin_clzll((uint64_t)(u >> 64)) : 64 + __builtin_clzll((uint64_t)u));
  int s = L > p ? L - p : 0;
  unsigned __int128 kept = u >> s, rem = s ? (u & (((unsigned __int128)1 << s) - 1)) : 0;
  if (rem) {
    *fl |= X_INEXACT;
    unsigned __int128 half = (unsigned __int128)1 << (s - 1);
    int inc = 0;
    if (mode == 0)
      inc = rem > half || (rem == half && (kept & 1));
    else if (mode == 0x800)
      inc = !neg;
    else if (mode == 0x400)
      inc = neg;
    kept += inc;
  }
  long double v = ldexpl((long double)kept, s);
  long double maxf = ldexpl(ldexpl(1, p) - 1, emax - p + 1);
  if (v > maxf) {
    *fl |= X_OVERFLOW | X_INEXACT;
    int toinf = mode == 0 || (mode == 0x800 && !neg) || (mode == 0x400 && neg);
    v = toinf ? INFINITY : maxf;
  }
  return neg ? -v : v;
}

static void test_itofp(const fmt_t *to, int nrand) {
  for (size_t wi = 0; wi < sizeof IW / sizeof IW[0]; ++wi) {
    int N = IW[wi];
    for (int sgn = 0; sgn <= 1; ++sgn) {
      long c0 = n_cases, b0 = n_bad;
      char wname[8];
      snprintf(wname, sizeof wname, "i%d", N);
      v128 edge[16];
      int ne = 0;
      v128 z = {{0, 0}}, one = {{1, 0}}, all = {{~0ull, ~0ull}};
      edge[ne++] = z;
      edge[ne++] = one;
      edge[ne++] = imask(all, N); /* -1 / UMAX */
      v128 smin = z, smax;
      if (N - 1 < 64) smin.w[0] = 1ull << (N - 1); else smin.w[1] = 1ull << (N - 1 - 64);
      edge[ne++] = smin;                         /* MIN */
      smax = imask((v128){{~smin.w[0], ~smin.w[1]}}, N);
      edge[ne++] = smax;                         /* MAX */
      v128 t = {{(1ull << 53) + 1, 0}}; edge[ne++] = imask(t, N);
      t.w[0] = (1ull << 24) + 1; edge[ne++] = imask(t, N);
      t.w[0] = (1ull << 11) + 1; edge[ne++] = imask(t, N);
      t.w[0] = 65520; edge[ne++] = imask(t, N);
      t.w[0] = 65519; edge[ne++] = imask(t, N);
      /* bf16 double rounding through f32 (CR §2 bf16 row, cq-ee9): 2^24 + 2^16 + 1 rounds to
       * 0x4b81 once, 0x4b80 through f32; likewise shifted into the i64 and i128 range */
      t.w[0] = 0x01010001; edge[ne++] = imask(t, N);
      t.w[0] = 0x01010001ull << 30; edge[ne++] = imask(t, N);
      t.w[0] = 0; t.w[1] = 0x01010001ull << 20; edge[ne++] = imask(t, N); t.w[1] = 0;
      for (int it = 0; it < ne + nrand; ++it) {
        v128 v = it < ne ? edge[it] : rand_int(N);
        v128 av[1] = {v};
        int ab[1] = {N};
        /* exact magnitude */
        int neg = 0;
        unsigned __int128 u = ((unsigned __int128)v.w[1] << 64) | v.w[0];
        if (sgn && N <= 128 && ((N <= 64 ? (v.w[0] >> (N - 1)) : (v.w[1] >> (N - 65))) & 1)) {
          neg = 1;
          unsigned __int128 full = N == 128 ? 0 : ((unsigned __int128)1 << N);
          u = full - u; /* mod 2^128 for N == 128 */
        }
        expect_t ex[4];
        int native = !small(to) && N <= 64 && !(sgn && N == 1);
        const char *src = native ? "native" : (sgn && N == 1 && !small(to) ? "table" : "reference");
        if (to == &BF16)
          src = "reference flags, value via f32";
        for (int mi = 0; mi < 4; ++mi) {
          ex[mi].val.w[1] = 0;
          if (native) {
            uint64_t r = 0;
            ex[mi].fl = (to->W == 32 ? nat_itofp_f32 : nat_itofp_f64)(N, sgn, v.w[0], MODES[mi], &r);
            ex[mi].val.w[0] = to->W == 32 ? (r & 0xFFFFFFFFull) : r;
            continue;
          }
          ex[mi].fl = 0;
          int p = to->fb + 1, emax = (1 << (to->eb - 1)) - 1;
          long double r = ref_int_round(u, neg, p, emax, MODES[mi], &ex[mi].fl);
          if (to == &BF16) { /* flags above (IEEE, one rounding); value: CR §2 bf16 row, via f32 */
            int dummy = 0;
            float f;
            if (N <= 64 && !(sgn && N == 1)) { /* the inline iN -> f32, native under the mode */
              uint64_t r32 = 0;
              nat_itofp_f32(N, sgn, v.w[0], MODES[mi], &r32);
              uint32_t b32 = (uint32_t)r32;
              memcpy(&f, &b32, 4);
            } else { /* compiler-rt (IEEE in the mode) */
              f = (float)ref_int_round(u, neg, 24, 127, MODES[mi], &dummy);
            }
            /* then compiler-rt f32 -> bf16: IEEE in the mode */
            ex[mi].val.w[0] = f == 0 ? 0 : encs(to, isinf(f) ? (double)f : ref_round(f, 8, -126, 127, MODES[mi], &dummy));
          } else if (small(to))
            ex[mi].val.w[0] = encs(to, (double)r);
          else if (to->W == 32) {
            float fv = (float)r;
            uint32_t b;
            memcpy(&b, &fv, 4);
            ex[mi].val.w[0] = b;
          } else {
            double d = (double)r;
            uint64_t b;
            memcpy(&b, &d, 8);
            ex[mi].val.w[0] = b;
          }
          if (u == 0)
            ex[mi].val.w[0] = 0; /* +0 */
        }
        check_forms(sgn ? "sitofp" : "uitofp", NULL, wname, to->name, 1, av, ab, 1, to->W, ex,
                    src);
      }
      printf("  %-8s %s->%s cases %8ld mismatches %ld\n", sgn ? "sitofp" : "uitofp", wname,
             to->name, n_cases - c0, n_bad - b0);
    }
  }
}

/* integer -> fp from more than 128 bits (CR §2 at CQ_spec 2f894fd): the VALUE is LLVM 19's
 * inline ExpandLargeFpConvert (nearest-even whatever the mode; the exponent wraps past the f32
 * range), measured by running native_ns.c; f16 is its f32 then the library fptrunc, IEEE in the
 * template's mode (reference). The _exc bits are IEEE at the operation's width in the mode
 * (native raises none): INEXACT iff not representable, OVERFLOW iff the rounded magnitude
 * exceeds the largest finite value. */
#define WW 18 /* words for i1100 */
static int wbit(const uint64_t *w, int i) { return (int)((w[i / 64] >> (i % 64)) & 1); }
static int wide_flags(const uint64_t *mag, int N, int neg, int p, int emax, int mode) {
  int L = 0, tz = -1;
  for (int i = N - 1; i >= 0; --i)
    if (wbit(mag, i)) {
      if (!L)
        L = i + 1;
      tz = i;
    }
  if (!L)
    return 0;
  int exact = L - tz <= p;
  int ovf = L - 1 > emax;
  if (!ovf && L - 1 == emax && !exact) { /* top p bits all ones and rounding up carries */
    int ones = 1;
    for (int i = L - 1; i >= L - p; --i)
      ones &= wbit(mag, i);
    int rb = wbit(mag, L - p - 1), st = 0;
    for (int i = L - p - 2; i >= 0; --i)
      st |= wbit(mag, i);
    int up = mode == 0 ? rb : mode == 0x800 ? !neg : mode == 0x400 ? neg : 0;
    ovf = ones && up;
    (void)st; /* any discarded bit: !exact */
  }
  if (ovf)
    return X_OVERFLOW | X_INEXACT;
  return exact ? 0 : X_INEXACT;
}
/* f32 bits -> f16/bf16 per IEEE in mode (a NaN quieted, high payload bits), the library fptrunc */
static uint64_t ref_f32_to_small(const fmt_t *to, uint32_t u, int mode) {
  float fv;
  memcpy(&fv, &u, 4);
  if (isnan(fv))
    return ((uint64_t)(u >> 31) << 15) | ((uint64_t)((1 << to->eb) - 1) << to->fb) |
           (1ull << (to->fb - 1)) | ((u & 0x7FFFFF) >> (23 - to->fb));
  if (isinf(fv) || fv == 0)
    return encs(to, (double)fv);
  int dummy = 0;
  return encs(to, ref_round((double)fv, to->fb + 1, 1 - sbias(to), sbias(to), mode, &dummy));
}
static void test_itofp_wide(int nrand) {
  static const int NW[] = {129, 200, 1100};
  const fmt_t *tos[4] = {&F16, &BF16, &F32, &F64};
  for (int ni = 0; ni < 3; ++ni)
    for (int ti = 0; ti < 4; ++ti)
      for (int sgn = 0; sgn <= 1; ++sgn) {
        int N = NW[ni], nw = (N + 63) / 64;
        const fmt_t *to = tos[ti];
        long c0 = n_cases, b0 = n_bad;
        char wname[8];
        snprintf(wname, sizeof wname, "i%d", N);
        int nedge = 14;
        for (int it = 0; it < nedge + nrand; ++it) {
          uint64_t w[WW];
          memset(w, 0, sizeof w);
          int k = it < nedge ? it : -1;
          switch (k) {
          case 0: break;                                       /* 0 */
          case 1: w[0] = 1; break;                             /* 1 */
          case 2: memset(w, 0xFF, sizeof w); break;            /* -1 / UMAX */
          case 3: w[(N - 1) / 64] = 1ull << ((N - 1) % 64); break; /* MIN / 2^(N-1) */
          case 4: memset(w, 0xFF, sizeof w); w[(N - 1) / 64] &= ~(1ull << ((N - 1) % 64)); break;
          case 5: w[2] = 1; break;                             /* 2^128 */
          case 6: w[0] = w[1] = ~0ull; break;                  /* 2^128 - 1 */
          case 7: w[1] = ~0ull << 40; break;                   /* 2^128 - 2^104 */
          case 8: w[1] = ~0ull << 39; break;                   /* 2^128 - 2^103: ties up */
          case 9: w[2] = 1ull << 22; break;                    /* 2^150 */
          case 10: w[1] = 1ull << 60 | 1ull << 52; w[0] = 1; break; /* bf16 double rounding */
          case 11: w[0] = (1ull << 24) + 1; break;
          case 12: w[16] = 1ull << 26; break;                  /* 2^1050 */
          case 13: w[15] = 1ull << 63; w[15] |= 1ull << 11; w[0] = 1; break; /* 2^1023 + ... */
          default: {
            for (int i = 0; i < nw; ++i)
              w[i] = rnd();
            int L = (int)(rnd() % N); /* leading bit at a random position, or all ones above */
            if (rnd() % 3) {
              for (int i = L + 1; i < nw * 64; ++i)
                w[i / 64] &= ~(1ull << (i % 64));
              w[L / 64] |= 1ull << (L % 64);
              if (rnd() % 2) /* few low bits: ties and exact values */
                for (int i = 0; i < L - 30 && i < nw * 64; ++i)
                  if (rnd() % 8)
                    w[i / 64] &= ~(1ull << (i % 64));
            } else {
              for (int i = L; i < nw * 64; ++i)
                w[i / 64] |= 1ull << (i % 64);
            }
          }
          }
          if (N % 64) /* bits above N zero */
            w[nw - 1] &= (1ull << (N % 64)) - 1;
          for (int i = nw; i < WW; ++i)
            w[i] = 0;
          /* magnitude for the flags */
          uint64_t mag[WW];
          memcpy(mag, w, sizeof mag);
          int neg = sgn && wbit(w, N - 1);
          if (neg) { /* 2^N - v */
            unsigned __int128 c = 1;
            for (int i = 0; i < nw; ++i) {
              unsigned __int128 t = (unsigned __int128)(~w[i]) + c;
              mag[i] = (uint64_t)t;
              c = t >> 64;
            }
            if (N % 64)
              mag[nw - 1] &= (1ull << (N % 64)) - 1;
          }
          expect_t ex[4];
          int p = to->fb + 1, emax = (1 << (to->eb - 1)) - 1;
          for (int mi = 0; mi < 4; ++mi) {
            ex[mi].fl = wide_flags(mag, N, neg, p, emax, MODES[mi]);
            ex[mi].val.w[1] = 0;
            if (small(to)) /* ExpandLargeFpConvert's f32, then IEEE fptrunc in the mode */
              ex[mi].val.w[0] = ref_f32_to_small(
                  to, (uint32_t)ns_wide_m(N, sgn, 32, w, FE_TONEAREST), MODES[mi]);
            else
              ex[mi].val.w[0] = ns_wide_m(N, sgn, to->W, w, MODES[mi]);
          }
          /* the value and _exc forms; the integer operand is N bits wide */
          for (int rm = 0; rm <= 2; ++rm)
            for (int exc = 0; exc <= 1; ++exc) {
              if (!exc && rm == 0)
                continue;
              for (int mi = 0; mi < 4; ++mi) {
                if (rm == 0 && mi != 0)
                  continue;
                cqe_tname t;
                memset(&t, 0, sizeof t);
                snprintf(t.op, sizeof t.op, "%s", sgn ? "sitofp" : "uitofp");
                snprintf(t.w, sizeof t.w, "%s", wname);
                snprintf(t.to, sizeof t.to, "%s", to->name);
                t.rm = (uint8_t)rm;
                t.exc = (uint8_t)exc;
                uint64_t store[WW], mstore[1];
                memcpy(store, w, sizeof store);
                cqe_val a[2] = {{(uint32_t)N, 'i', (uint32_t)nw, store}, {32, 'i', 1, mstore}};
                uint64_t m = (uint64_t)(uint32_t)MODES[mi];
                if (rm == 2)
                  m |= rnd() & 0xFFFFF3FFull;
                mstore[0] = m & 0xFFFFFFFFull;
                int rb = exc ? 32 : to->W;
                uint64_t ow[2] = {0, 0};
                cqe_val out = {(uint32_t)rb, 'i', 1, ow};
                int rc = mock_dispatch(&t, a, rm ? 2 : 1, &out);
                n_cases++;
                form_t f = {t.op, NULL, wname, to->name, rm, exc};
                v128 av[1] = {{{w[0], w[1]}}};
                v128 want = {{exc ? (uint64_t)ex[mi].fl : ex[mi].val.w[0], 0}};
                v128 got = {{ow[0], 0}};
                if (rc != 0) {
                  v128 z = {{(uint64_t)rc, 0}};
                  report(&f, mi, av, 1, "rc", &z, &want, "wide");
                } else if (got.w[0] != want.w[0]) {
                  report(&f, mi, av, 1, exc ? "exc" : "value", &got, &want,
                         exc ? "IEEE flags" : (small(to) ? "native f32 + IEEE fptrunc"
                                                         : "native-nonstrict"));
                }
              }
            }
        }
        printf("  %-8s %s->%s cases %8ld mismatches %ld\n", sgn ? "sitofp" : "uitofp", wname,
               to->name, n_cases - c0, n_bad - b0);
      }
}

/* fp -> integer, _exc only */
static void test_toint(const fmt_t *from, const uint64_t *xs, int nx, int nrand) {
  for (size_t wi = 0; wi < sizeof IW / sizeof IW[0]; ++wi) {
    int N = IW[wi];
    for (int sgn = 0; sgn <= 1; ++sgn) {
      long c0 = n_cases, b0 = n_bad;
      char wname[8];
      snprintf(wname, sizeof wname, "i%d", N);
      for (int it = 0; it < nx + nrand; ++it) {
        uint64_t a = it < nx ? xs[it] : rand_val(from);
        v128 av[1] = {{{a, 0}}};
        int ab[1] = {from->W};
        expect_t ex[4];
        const char *src;
        for (int mi = 0; mi < 4; ++mi) {
          ex[mi].val.w[0] = ex[mi].val.w[1] = 0;
          /* the operand as a native float/double (f16 via f32, CR §2: sNaN keeps INVALID, which
           * the conversion raises on any NaN anyway) */
          float fv = 0;
          double dv = 0;
          int use32 = from->W != 64;
          if (small(from)) {
            fv = (float)decs(from, a);
          } else if (from->W == 32) {
            uint32_t u = (uint32_t)a;
            memcpy(&fv, &u, 4);
          } else
            memcpy(&dv, &a, 8);
          if (N > 64) { /* IEEE at width N */
            src = "reference";
            long double x = use32 ? (long double)fv : (long double)dv;
            int fl = 0;
            if (isnan(x) || isinf(x))
              fl = X_INVALID;
            else {
              long double tr = truncl(x);
              int ok = sgn ? (tr >= -ldexpl(1, N - 1) && tr < ldexpl(1, N - 1))
                           : (tr > -1.0L && tr < ldexpl(1, N));
              fl = !ok ? X_INVALID : (tr != x ? X_INEXACT : 0);
            }
            ex[mi].fl = fl;
            continue;
          }
          int Nn = (sgn && N == 1) ? 32 : N; /* fptosi to i1: LLVM promotes to i32 (cvtt32) */
          src = (sgn && N == 1) ? "native(i32)" : "native";
          if (use32)
            ex[mi].fl = nat_toint_f32(Nn, sgn, &fv, MODES[mi]);
          else
            ex[mi].fl = nat_toint_f64(Nn, sgn, &dv, MODES[mi]);
        }
        check_forms(sgn ? "fptosi" : "fptoui", NULL, from->name, wname, 0, av, ab, 1, N, ex, src);
      }
      printf("  %-8s %s->%s cases %8ld mismatches %ld\n", sgn ? "fptosi" : "fptoui", from->name,
             wname, n_cases - c0, n_bad - b0);
    }
  }
}

/* ------------------------------------------------------------------------------------------- */
/* Claims: plain and f80 forms decline; fcmps is claimed in every form; no handler fails. */
static void test_claims(void) {
  const char *ops[] = {"fadd", "fsub", "fmul", "fdiv", "fma", "sqrt", "frem", "fcmp", "fcmps",
                       "fptrunc", "fpext", "sitofp", "uitofp", "fptosi", "fptoui", "rint",
                       "floor", "ceil", "trunc", "round", "fmax", "fmin"};
  long c0 = n_cases, b0 = n_bad;
  for (size_t i = 0; i < sizeof ops / sizeof ops[0]; ++i) {
    n_cases++;
    if (!mock_registered(ops[i])) {
      printf("MISMATCH claims: %s not registered\n", ops[i]);
      n_bad++;
    }
    v128 av[3] = {{{0, 0}}, {{0, 0}}, {{0, 0}}};
    int ab[3] = {64, 64, 64};
    int nargs = !strcmp(ops[i], "fma") ? 3
                : (!strcmp(ops[i], "fadd") || !strcmp(ops[i], "fsub") || !strcmp(ops[i], "fmul") ||
                   !strcmp(ops[i], "fdiv") || !strcmp(ops[i], "frem") || !strcmp(ops[i], "fcmp") ||
                   !strcmp(ops[i], "fcmps") || !strcmp(ops[i], "fmax") || !strcmp(ops[i], "fmin"))
                    ? 2
                    : 1;
    int is_cmp = !strncmp(ops[i], "fcmp", 4);
    /* plain f64 form: declined unless fcmps */
    form_t f = {ops[i], is_cmp ? "ogt" : NULL, "f64", NULL, 0, 0};
    v128 got;
    int rc = call_mine(&f, av, ab, nargs, 0, is_cmp ? 1 : 64, &got);
    int want = !strcmp(ops[i], "fcmps") ? 0 : 1;
    n_cases++;
    if (rc != want) {
      printf("MISMATCH claims: plain %s rc %d want %d\n", ops[i], rc, want);
      n_bad++;
    }
    /* f80 _exc form: declined */
    form_t g = {ops[i], is_cmp ? "ogt" : NULL, "f80", NULL, 0, 1};
    int ab80[3] = {80, 80, 80};
    v128 av80[3] = {{{0, 0}}, {{0, 0}}, {{0, 0}}};
    rc = call_mine(&g, av80, ab80, nargs, 0, 32, &got);
    n_cases++;
    if (rc != 1) {
      printf("MISMATCH claims: f80 %s_exc rc %d want 1\n", ops[i], rc);
      n_bad++;
    }
  }
  /* integer trunc cast is never this family's */
  form_t tr = {"trunc", NULL, "i64", "i32", 0, 1};
  v128 a1[1] = {{{0, 0}}};
  int b1[1] = {64};
  v128 got;
  n_cases++;
  if (call_mine(&tr, a1, b1, 1, 0, 32, &got) != 1) {
    printf("MISMATCH claims: trunc_i64_to_i32 claimed\n");
    n_bad++;
  }
  printf("  %-8s           cases %8ld mismatches %ld\n", "claims", n_cases - c0, n_bad - b0);
}

/* The corpus forms (80, 81, 82, 100) by their exact spellings, spot values from the examples'
 * stated semantics. */
static void test_corpus_spellings(void) {
  long c0 = n_cases, b0 = n_bad;
  struct {
    const char *op, *pred;
    int rm, exc, nargs, mode;
    double a, b;
    uint64_t want;
  } cs[] = {
      /* 1/3 rounded down and up differ in the last bit */
      {"fdiv", NULL, 1, 0, 2, 0x400, 1.0, 3.0, 0x3FD5555555555555ull},
      {"fdiv", NULL, 1, 0, 2, 0x800, 1.0, 3.0, 0x3FD5555555555556ull},
      {"fdiv", NULL, 1, 1, 2, 0x000, 1.0, 0.0, X_DIVBYZERO},
      {"fdiv", NULL, 1, 1, 2, 0xC00, 1.0, 3.0, X_INEXACT},
      {"fmul", NULL, 1, 1, 2, 0x000, 1e308, 10.0, X_OVERFLOW | X_INEXACT},
      {"fmul", NULL, 1, 0, 2, 0xC00, 1e308, 10.0, 0x7FEFFFFFFFFFFFFFull},
      {"fadd", NULL, 2, 0, 2, 0x400, 1.0, 0x1p-60, 0x3FF0000000000000ull},
      {"fadd", NULL, 2, 0, 2, 0x800, 1.0, 0x1p-60, 0x3FF0000000000001ull},
      {"fmul", NULL, 1, 1, 2, 0x000, 0x1.0000000000001p-1022, 0.5, X_UNDERFLOW | X_INEXACT},
      {"fadd", NULL, 1, 1, 2, 0x000, 0x1p-1022, -0x1p-1074, 0},
      {"fcmps", "ogt", 0, 1, 2, 0, NAN, 1.0, X_INVALID},
      {"fcmps", "ogt", 0, 1, 2, 0, 2.0, 1.0, 0},
  };
  for (size_t i = 0; i < sizeof cs / sizeof cs[0]; ++i) {
    form_t f = {cs[i].op, cs[i].pred, "f64", NULL, cs[i].rm, cs[i].exc};
    uint64_t ab_[2];
    memcpy(&ab_[0], &cs[i].a, 8);
    memcpy(&ab_[1], &cs[i].b, 8);
    v128 av[2] = {{{ab_[0], 0}}, {{ab_[1], 0}}};
    int ab[2] = {64, 64};
    v128 got, want = {{cs[i].want, 0}};
    int rc = call_mine(&f, av, ab, 2, cs[i].mode, cs[i].exc ? 32 : 64, &got);
    n_cases++;
    if (rc != 0 || got.w[0] != want.w[0])
      report(&f, cs[i].mode >> 10, av, 2, "corpus", &got, &want, "spelling");
  }
  printf("  %-8s           cases %8ld mismatches %ld\n", "corpus", n_cases - c0, n_bad - b0);
}

int main(int argc, char **argv) {
  const char *full_env = getenv("CQ_FULL");
  int full_mode = full_env && *full_env && strcmp(full_env, "0"); /* cq-m4s9 */
  int nrand = argc > 1 ? atoi(argv[1]) : full_mode ? 4000 : 200;
  printf("tmpl-fenv difftest (%s): seed %016llx, %d random per op and width\n",
         full_mode ? "CQ_FULL" : "quick", (unsigned long long)rs, nrand);
  test_claims();
  test_corpus_spellings();
  const fmt_t *fs[4] = {&F16, &BF16, &F32, &F64};
  uint64_t xs[4][128];
  int nx[4];
  for (int i = 0; i < 4; ++i)
    nx[i] = edges(fs[i], xs[i]);
  for (int i = 0; i < 4; ++i) {
    test_binary(fs[i], xs[i], nx[i], nrand);
    test_fma(fs[i], xs[i], nx[i], nrand);
    test_unary(fs[i], xs[i], nx[i], nrand);
    test_cmp(fs[i], xs[i], nx[i], nrand);
    test_itofp(fs[i], nrand);
    test_toint(fs[i], xs[i], nx[i], nrand);
  }
  test_itofp_wide(nrand / 4);
  for (int i = 0; i < 4; ++i)
    for (int j = 0; j < 4; ++j)
      if (i != j && fs[i]->W != fs[j]->W)
        test_fpconv(fs[i], fs[j], xs[i], nx[i], nrand);
  printf("TOTAL cases %ld mismatches %ld cqe_fail %d\n", n_cases, n_bad, mock_fail_count);
  return (n_bad || mock_fail_count) ? 1 : 0;
}
