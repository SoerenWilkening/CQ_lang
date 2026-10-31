/* Checker template family: every fp template at x86_fp80 (cq-w0-tmpl-f80).
 *
 * Evaluator semantics, on basis values, of every fp template whose operand width W or cast target
 * W2 is f80: fadd fsub fmul fdiv frem fneg fma sqrt fcmp fcmps fabs copysign fmax fmin floor ceil
 * trunc rint round is_fpclass fpext fptrunc sitofp uitofp fptosi fptoui, each with its _rm, _rmq
 * and _exc forms. (select_f80 is tmpl-cmp's, bitcast f80<->i80 is tmpl-int's, qrom_load_f80 with
 * its 16-byte element stride is rt-mem's.) Semantics: CONSTRUCTION_RULES §1.2 and §2 (normative),
 * BACKEND_ABI §2.1, §2.6, §2.9, §2.10.
 *
 * Arithmetic runs on the host x87 through `long double` (64-bit significand, precision control
 * extended), the rounding mode set with fesetround and the exception bits read with fetestexcept,
 * so f80 is x87 extended exactly as CR §2 says ("x87 extended, same rounding rule"). Where CR §2
 * fixes a result the host x87 or libm does not give, the table is implemented instead:
 *   - non-canonical encodings (pseudo-NaN, pseudo-Inf, unnormal) are an invalid operand: an fp
 *     result is the real indefinite 0xFFFF_C000000000000000 and INVALID is raised; a compare is
 *     unordered with INVALID; a conversion reads the real indefinite (a NaN) with INVALID.
 *     Pseudo-denormals read as denormals. fneg, fabs and copysign are sign-bit operations and
 *     is_fpclass is a pure bit test: they read no value;
 *   - fptosi/fptoui are x87 fist (truncating) with the indefinite INT_MIN of the fist width, at the
 *     widths of the CR §2 f80 row: s8 = trunc(fist16), s16 = fist16, s32 = fist32, s64 = fist64,
 *     u8 = trunc(fist16), u16 = trunc(fist32), u32 = trunc(fist64), u64 = x < 2^63 ? fist64(x) :
 *     fist64(x - 2^63) ^ 2^63. Every other width N follows x86-64 LLVM 19 -O1 code (fix_int);
 *   - the NaN row: an fp arithmetic result that is a NaN is the first NaN operand in IR order,
 *     quieted, or, for an invalid operation, the real indefinite (the f80 default NaN; CR §2 names
 *     the f16/f32/f64 ones). This replaces the x87 larger-significand rule and libm's choice;
 *   - fmax/fmin: isnan(a) ? b : isnan(b) ? a : (b > a ? b : a) (min with <), equal values give a,
 *     two NaNs give b unchanged; _exc raises INVALID iff an operand is a signaling NaN or
 *     non-canonical, else nothing (CR §2 / cq-qx1: IEEE maxNum over the libm call);
 *   - rint rounds in the current mode: the host's (fegetround) for plain rint, the template's mode for _rm/_rmq
 *     (CR §2 at CQ_spec 2f894fd); sitofp/uitofp from at most 128 bits and fptrunc to f16/bf16
 *     are correctly rounded in the template's mode (software rounding); sitofp/uitofp from more
 *     than 128 bits round twice as LLVM 19 does (to 113 bits nearest even, then to f80 in the
 *     mode), except uitofp with the top bit set: non-negative, rounded once in the mode (CR §2,
 *     cq-off6, cq-cqcj, cq-6d9d).
 *
 * Calling convention of the registered cqe_op_fn (what the core dispatcher hands a family):
 *   - tname: the parsed template name. tname->w is the operand width (the source of a cast),
 *     tname->to the cast target, tname->pred the fcmp predicate, tname->rm 0 (none), 1 (_rm, an
 *     i32 literal) or 2 (_rmq, an i32 rail), tname->exc 1 for _exc. Shape and unc do not change the
 *     value: forward and _unc are the same XOR map (BACKEND_ABI §2.1), applied by the caller.
 *   - args: the DATA operands in signature order (IR operand order, whatever the shape), handles
 *     resolved to their basis values and literals as values, then the mode when tname->rm != 0
 *     (cq-mgi M1: every forward-call argument in signature order; _unc's out handle not passed).
 *     Only the low W bits of an operand are read; words beyond args[i].nw read 0.
 *   - out: receives f(args): the result (W, or W2 for a cast, i1 for fcmp/fcmps/is_fpclass) or,
 *     for _exc, the i32 exception bits INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32.
 *     The core owns it (cq-mgi M1): out->w holds out->nw >= ceil(bits/64) words, bits and kind are
 *     preset; every one of the nw words is written (high bits zero), nothing else is touched.
 *   - return 0 on success, -1 on a malformed call (bad width, arity, predicate, short out; the
 *     violation goes to cqe_fail), and CQE_OP_NOT_MINE (1) without touching out when the template
 *     has no f80 operand or result: the op names are shared with tmpl-fp, tmpl-fpmisc and
 *     tmpl-fenv, and the dispatcher hands such a template to the family of its width.
 */
#pragma STDC FENV_ACCESS ON

#include <fenv.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

#ifndef CQE_OP_NOT_MINE
#define CQE_OP_NOT_MINE 1
#endif

enum { X_INVALID = 1, X_DIVBYZERO = 4, X_OVERFLOW = 8, X_UNDERFLOW = 16, X_INEXACT = 32 };

/* ---------------------------------------------------------------- widths and values */

typedef struct {
  char kind;     /* 'i', 'f', or 'b' (bf16) */
  uint32_t bits; /* N */
} wid_t;

static int parse_wid(const char *s, wid_t *o) {
  if (!strcmp(s, "bf16")) {
    o->kind = 'b';
    o->bits = 16;
    return 0;
  }
  if (s[0] != 'i' && s[0] != 'f') return -1;
  if (s[1] < '1' || s[1] > '9') return -1;
  unsigned long n = 0;
  for (const char *p = s + 1; *p; ++p) {
    if (*p < '0' || *p > '9') return -1;
    n = n * 10 + (unsigned long)(*p - '0');
    if (n > (1ul << 24)) return -1;
  }
  if (s[0] == 'f' && n != 16 && n != 32 && n != 64 && n != 80) return -1;
  o->kind = s[0];
  o->bits = (uint32_t)n;
  return 0;
}

static uint32_t nwords(uint32_t bits) { return (bits + 63) / 64; }

static uint64_t word(const cqe_val *v, uint32_t i) { return (v->w && i < v->nw) ? v->w[i] : 0; }

/* The low `bits` bits of v as nwords(bits) fresh words. */
static uint64_t *read_bits(const cqe_val *v, uint32_t bits) {
  uint32_t n = nwords(bits);
  uint64_t *x = calloc(n ? n : 1, sizeof *x);
  if (!x) abort();
  for (uint32_t i = 0; i < n; ++i) x[i] = word(v, i);
  if (bits % 64) x[n - 1] &= (UINT64_C(1) << (bits % 64)) - 1;
  return x;
}

typedef struct {
  uint64_t m;  /* significand, explicit integer bit J = bit 63 */
  uint16_t se; /* sign (bit 15) and biased exponent */
} f80b;

static f80b f80_of_val(const cqe_val *v) {
  f80b b;
  b.m = word(v, 0);
  b.se = (uint16_t)(word(v, 1) & 0xFFFF);
  return b;
}

static long double ld_of(f80b b) {
  long double x;
  memset(&x, 0, sizeof x);
  memcpy(&x, &b.m, 8);
  memcpy((char *)&x + 8, &b.se, 2);
  return x;
}

static f80b bits_of(long double x) {
  f80b b;
  memcpy(&b.m, &x, 8);
  memcpy(&b.se, (char *)&x + 8, 2);
  return b;
}

static const f80b F80_INDEF = {UINT64_C(0xC000000000000000), 0xFFFF};

/* Pseudo-NaN, pseudo-Inf and unnormal: the x87 invalid-operand encodings (CR §2). */
static int f80_noncanonical(f80b b) {
  unsigned e = b.se & 0x7FFF;
  int j = (int)(b.m >> 63);
  return e != 0 && !j;
}

static int f80_isnan(f80b b) {
  return (b.se & 0x7FFF) == 0x7FFF && (b.m << 1) != 0; /* J = 1 (canonical) and fraction != 0 */
}

/* ---------------------------------------------------------------- the out value */

/* The core owns the output (cq-mgi M1): out->w holds out->nw >= ceil(bits/64) zeroed words and
 * out->bits/out->kind are preset to the result type. The handler only writes words. */
static int out_begin(cqe_val *out, uint32_t bits, char kind) {
  uint32_t need = nwords(bits);
  if (!out->w || out->nw < need) {
    cqe_fail("tmpl-f80: out holds %u words, the %c%u result needs %u", out->w ? (unsigned)out->nw : 0u, kind,
             (unsigned)bits, (unsigned)need);
    return -1;
  }
  memset(out->w, 0, (size_t)out->nw * sizeof *out->w);
  return 0;
}

/* ---------------------------------------------------------------- the host FPU */

typedef struct {
  fenv_t saved;
} fpu_t;

static int rc_of(uint32_t mode) {
  switch ((mode >> 10) & 3) {
  case 0: return FE_TONEAREST;
  case 1: return FE_DOWNWARD;
  case 2: return FE_UPWARD;
  default: return FE_TOWARDZERO;
  }
}

static void fpu_enter(fpu_t *f, int rc) {
  fegetenv(&f->saved);
  fesetround(rc);
  feclearexcept(FE_ALL_EXCEPT);
}

static int fpu_leave(fpu_t *f) {
  int r = fetestexcept(FE_ALL_EXCEPT);
  fesetenv(&f->saved);
  int x = 0;
  if (r & FE_INVALID) x |= X_INVALID;
  if (r & FE_DIVBYZERO) x |= X_DIVBYZERO;
  if (r & FE_OVERFLOW) x |= X_OVERFLOW;
  if (r & FE_UNDERFLOW) x |= X_UNDERFLOW;
  if (r & FE_INEXACT) x |= X_INEXACT;
  return x;
}

/* x87 truncating stores (fisttp, SSE3: the corpus CPU penryn has it, and LLVM 19 -O1 uses it):
 * out-of-range, NaN and Inf give the integer indefinite (INT_MIN of the store width) and INVALID. */
static int16_t fist16(long double x) {
  int16_t r;
  __asm__ volatile("fisttps %0" : "=m"(r) : "t"(x) : "st");
  return r;
}
static int32_t fist32(long double x) {
  int32_t r;
  __asm__ volatile("fisttpl %0" : "=m"(r) : "t"(x) : "st");
  return r;
}
static int64_t fist64(long double x) {
  int64_t r;
  __asm__ volatile("fisttpll %0" : "=m"(r) : "t"(x) : "st");
  return r;
}

/* ---------------------------------------------------------------- software rounding
 *
 * round_to rounds (-1)^sign * M * 2^E (M a little-endian multiword magnitude) to a binary format
 * of p significand bits (leading bit included) whose leading-bit exponent lies in [emin, emax],
 * under rc, with x86 flags: INEXACT; OVERFLOW (with INEXACT); UNDERFLOW when the result is tiny
 * after rounding (tininess after rounding) and inexact. The result is the integer significand q
 * and the exponent lsb of its last bit: value = q * 2^lsb, q < 2^p. *inf is set on overflow to
 * infinity; on overflow to the largest finite value q = 2^p - 1 and lsb = emax - p + 1. */

static uint32_t mw_bitlen(const uint64_t *M, uint32_t nw) {
  for (uint32_t i = nw; i-- > 0;)
    if (M[i]) return i * 64 + 64 - (uint32_t)__builtin_clzll(M[i]);
  return 0;
}

static int mw_bit(const uint64_t *M, uint32_t nw, long i) {
  if (i < 0 || (uint64_t)i >= (uint64_t)nw * 64) return 0;
  return (int)((M[i / 64] >> (i % 64)) & 1);
}

static int mw_any_below(const uint64_t *M, uint32_t nw, long n) { /* any of bits [0, n) set */
  for (long i = 0; i < n && (uint64_t)i < (uint64_t)nw * 64; ++i)
    if (mw_bit(M, nw, i)) return 1;
  return 0;
}

/* Bits [s, s + 65) of M as an unsigned __int128 (s may be negative: a left shift). */
static unsigned __int128 mw_extract(const uint64_t *M, uint32_t nw, long s) {
  unsigned __int128 q = 0;
  for (int i = 64; i >= 0; --i) q = (q << 1) | (unsigned)mw_bit(M, nw, s + i);
  return q;
}

/* Round M >> s (s >= 0 bits dropped) per rc; returns q, sets *inexact. */
static unsigned __int128 round_shift(const uint64_t *M, uint32_t nw, long s, int sign, int rc, int *inexact) {
  unsigned __int128 q = mw_extract(M, nw, s);
  if (s <= 0) {
    *inexact = 0;
    return q;
  }
  int guard = mw_bit(M, nw, s - 1);
  int sticky = mw_any_below(M, nw, s - 1);
  *inexact = guard || sticky;
  int inc = 0;
  switch (rc) {
  case FE_TONEAREST: inc = guard && (sticky || (int)(q & 1)); break;
  case FE_UPWARD: inc = !sign && (guard || sticky); break;
  case FE_DOWNWARD: inc = sign && (guard || sticky); break;
  default: inc = 0; break;
  }
  return q + (unsigned)inc;
}

typedef struct {
  int p;
  long emin, emax;
} fmt_t;

static int round_to(int sign, const uint64_t *M, uint32_t nw, long E, fmt_t f, int rc, uint64_t *q_out,
                    long *lsb_out, int *inf) {
  int flags = 0, inexact;
  *inf = 0;
  uint32_t L = mw_bitlen(M, nw);
  long x = (long)L - 1 + E; /* exponent of the leading bit */
  /* Tininess after rounding: round to p bits with an unbounded exponent range. */
  {
    long s = (long)L - f.p;
    unsigned __int128 q = round_shift(M, nw, s, sign, rc, &inexact);
    long xu = x + ((q >> f.p) ? 1 : 0);
    if (xu < f.emin) flags |= X_UNDERFLOW; /* kept only if inexact, below */
  }
  long lsb = (x > f.emin ? x : f.emin) - (f.p - 1);
  long s = lsb - E;
  unsigned __int128 q = round_shift(M, nw, s, sign, rc, &inexact);
  if (q >> f.p) {
    q >>= 1;
    ++lsb;
  }
  if (inexact)
    flags |= X_INEXACT;
  else
    flags &= ~X_UNDERFLOW;
  int normal = (q >> (f.p - 1)) & 1;
  if (normal && lsb + f.p - 1 > f.emax) {
    flags |= X_OVERFLOW | X_INEXACT;
    flags &= ~X_UNDERFLOW;
    int to_inf = rc == FE_TONEAREST || (rc == FE_UPWARD && !sign) || (rc == FE_DOWNWARD && sign);
    if (to_inf) {
      *inf = 1;
      q = 0;
    } else {
      q = ((unsigned __int128)1 << f.p) - 1;
      lsb = f.emax - f.p + 1;
    }
  }
  *q_out = (uint64_t)q;
  *lsb_out = lsb;
  return flags;
}

static const fmt_t FMT_F80 = {64, -16382, 16383};

static f80b f80_encode(int sign, uint64_t q, long lsb, int inf) {
  f80b b;
  uint16_t s = sign ? 0x8000 : 0;
  if (inf) {
    b.m = UINT64_C(0x8000000000000000);
    b.se = s | 0x7FFF;
  } else if (q == 0) {
    b.m = 0;
    b.se = s;
  } else if (q >> 63) {
    b.m = q;
    b.se = s | (uint16_t)(lsb + 63 + 16383);
  } else {
    b.m = q; /* subnormal: lsb = -16445 */
    b.se = s;
  }
  return b;
}

/* The two 16-bit formats: binary16 and bfloat16 (CR §1.1: 8 exponent bits, 7 fraction bits, the
 * IEEE rounding and NaN rules). */
typedef struct {
  fmt_t f;
  int fbits;          /* stored fraction bits */
  uint16_t inf, qbit; /* +Inf pattern, quiet bit */
} narrow_t;
static const narrow_t N_F16 = {{11, -14, 15}, 10, 0x7C00, 0x0200};
static const narrow_t N_BF16 = {{8, -126, 127}, 7, 0x7F80, 0x0040};

static uint16_t narrow_encode(const narrow_t *n, int sign, uint64_t q, long lsb, int inf) {
  uint16_t s = sign ? 0x8000 : 0;
  if (inf) return s | n->inf;
  if (q == 0) return s;
  uint64_t lead = UINT64_C(1) << n->fbits;
  if (q & lead)
    return s | (uint16_t)((lsb + n->fbits - n->f.emin + 1) << n->fbits) | (uint16_t)(q & (lead - 1));
  return s | (uint16_t)q;
}

/* ---------------------------------------------------------------- 16-bit formats <-> f80 */

/* f80 -> binary16/bfloat16, correctly rounded in rc (LLVM calls __truncxfhf2 for half; the result
 * is the IEEE one). NaN: quiet, sign kept, payload the top fraction bits; a signaling NaN raises
 * INVALID. */
static uint16_t f80_to_narrow(const narrow_t *n, f80b b, int rc, int *flags) {
  int sign = b.se >> 15;
  unsigned e = b.se & 0x7FFF;
  uint16_t s = sign ? 0x8000 : 0;
  if (e == 0x7FFF) {
    if ((b.m << 1) == 0) return s | n->inf;
    if (!((b.m >> 62) & 1)) *flags |= X_INVALID;
    return s | n->inf | n->qbit | (uint16_t)((b.m << 2) >> (64 - (n->fbits - 1)));
  }
  if (b.m == 0) return s;
  uint64_t M[1] = {b.m};
  long E = (long)(e ? e : 1) - 16383 - 63;
  uint64_t q;
  long lsb;
  int inf;
  *flags |= round_to(sign, M, 1, E, n->f, rc, &q, &lsb, &inf);
  return narrow_encode(n, sign, q, lsb, inf);
}

/* binary16 -> binary32 bits, exact; a signaling NaN stays signaling (as __extendhfsf2), so the x87
 * load that follows quiets it and raises INVALID, as the native code does. */
static uint32_t f16_to_f32_bits(uint16_t h) {
  uint32_t s = (uint32_t)(h >> 15) << 31;
  uint32_t e = (h >> 10) & 0x1F, m = h & 0x3FF;
  if (e == 0x1F) return s | 0x7F800000u | (m << 13);
  if (e == 0) {
    if (m == 0) return s;
    int sh = 0;
    while (!(m & 0x400)) {
      m <<= 1;
      ++sh;
    }
    m &= 0x3FF;
    return s | ((uint32_t)(113 - sh) << 23) | (m << 13);
  }
  return s | ((e + 112) << 23) | (m << 13);
}

/* ---------------------------------------------------------------- f80 -> integer
 *
 * fix_int writes the N-bit result of fptosi (sgn = 1) or fptoui (sgn = 0) of x into r[nwords(N)]
 * and returns the exception bits. x is canonical or pseudo-denormal (callers substitute the real
 * indefinite for a non-canonical operand). Widths:
 *   - CR §2 f80 row: s8/s16 fist16, s32 fist32, s64 fist64, u8 trunc(fist16), u16 trunc(fist32),
 *     u32 trunc(fist64), u64 x < 2^63 ? fist64(x) : fist64(x - 2^63) ^ 2^63;
 *   - other N <= 64, as LLVM 19 -O1 promotes them: signed through the narrowest fist of 16/32/64
 *     bits >= N, unsigned through the narrowest one > N, then truncated;
 *   - 64 < N <= 128: compiler-rt __fixxfti / __fixunsxfti (the libcalls LLVM emits), truncated;
 *     the exception bits are those of an x87 conversion at 128 bits (CR §2: a NaN operand to an
 *     integer conversion raises INVALID): INVALID for NaN, Inf or a value outside the 128-bit range,
 *     else INEXACT for a fraction;
 *   - N > 128: LLVM's ExpandLargeFpConvert (through fp128): |x| < 1 gives 0, an unbiased exponent
 *     >= N saturates to the signed N-bit extreme of x's sign (NaN and Inf included), otherwise
 *     +-floor(|x|) mod 2^N; exception bits as above at N bits. */

static void put_u64(uint64_t *r, uint32_t N, uint64_t v, int sext) {
  uint32_t n = nwords(N);
  for (uint32_t i = 0; i < n; ++i) r[i] = i == 0 ? v : (sext && (int64_t)v < 0 ? ~UINT64_C(0) : 0);
  if (N % 64) r[n - 1] &= (UINT64_C(1) << (N % 64)) - 1;
}

/* floor(|x|) as a multiword magnitude in mag[n] (bits beyond n words dropped); x finite. */
static void f80_floor_mag(f80b b, uint64_t *mag, uint32_t n) {
  memset(mag, 0, (size_t)n * sizeof *mag);
  long e = (long)(b.se & 0x7FFF) - 16383; /* exponent of bit 63 of m */
  if ((b.se & 0x7FFF) == 0) return;       /* zero, denormal, pseudo-denormal: |x| < 1 */
  if (e < 0) return;
  for (int i = 63; i >= 0; --i) {
    if (!((b.m >> i) & 1)) continue;
    long pos = e - (63 - i);
    if (pos < 0) break;
    if ((uint64_t)pos < (uint64_t)n * 64) mag[pos / 64] |= UINT64_C(1) << (pos % 64);
  }
}

static int f80_has_fraction(f80b b) {
  unsigned eb = b.se & 0x7FFF;
  if (b.m == 0) return 0;
  long e = (long)(eb ? eb : 1) - 16383;
  if (e >= 63) return 0;
  if (e < 0) return 1;
  return (b.m << (e + 1)) != 0;
}

static void mw_negate(uint64_t *r, uint32_t n) {
  unsigned carry = 1;
  for (uint32_t i = 0; i < n; ++i) {
    uint64_t v = ~r[i] + carry;
    carry = carry && v == 0;
    r[i] = v;
  }
}

/* x87-style flags of converting x (canonical or pseudo-denormal) to a C-bit integer with
 * truncation: INVALID for NaN, Inf or trunc(x) outside the signed (sgn) or unsigned C-bit range,
 * else INEXACT when x has a fraction. */
static int conv_flags(f80b b, uint32_t C, int sgn) {
  unsigned eb = b.se & 0x7FFF;
  int neg = b.se >> 15;
  if (eb == 0x7FFF) return X_INVALID;
  long e = (long)eb - 16383; /* floor(|x|) >= 1 has e + 1 bits when eb != 0, e >= 0, m != 0 */
  if (eb != 0 && e >= 0 && (b.m >> (e >= 63 ? 0 : 63 - e)) != 0) {
    /* floor(|x|) is a power of two iff the bits of m below J that are integer bits are zero */
    int pow2 = e >= 63 ? b.m == UINT64_C(0x8000000000000000) : e == 0 ? 1 : ((b.m << 1) >> (64 - e)) == 0;
    if (sgn) {
      if (!neg && e >= (long)C - 1) return X_INVALID;
      if (neg && (e >= (long)C || (e == (long)C - 1 && !pow2))) return X_INVALID;
    } else {
      if (neg || e >= (long)C) return X_INVALID;
    }
  }
  return f80_has_fraction(b) ? X_INEXACT : 0;
}

static int fix_int(f80b b, uint32_t N, int sgn, uint64_t *r) {
  long double x = ld_of(b);
  fpu_t f;
  if (N <= 64) {
    uint64_t v;
    int sext = 0;
    fpu_enter(&f, FE_TONEAREST);
    if (sgn) {
      if (N <= 16)
        v = (uint64_t)(int64_t)fist16(x);
      else if (N <= 32)
        v = (uint64_t)(int64_t)fist32(x);
      else
        v = (uint64_t)fist64(x);
      sext = 1;
    } else if (N == 16) {
      v = (uint64_t)(int64_t)fist32(x); /* CR §2: u16 = trunc(fist32) */
    } else if (N < 16) {
      v = (uint64_t)(int64_t)fist16(x); /* CR §2: u8 = trunc(fist16), as every N < 16 */
    } else if (N < 32) {
      v = (uint64_t)(int64_t)fist32(x);
    } else if (N < 64) {
      v = (uint64_t)fist64(x);
    } else { /* u64 */
      const long double two63 = 9223372036854775808.0L;
      if (__builtin_isless(x, two63))
        v = (uint64_t)fist64(x);
      else
        v = (uint64_t)fist64(x - two63) ^ (UINT64_C(1) << 63);
    }
    int fl = fpu_leave(&f);
    put_u64(r, N, v, sext);
    return fl;
  }
  uint32_t n = nwords(N);
  unsigned eb = b.se & 0x7FFF;
  int neg = b.se >> 15;
  long e = (long)eb - 16383;
  if (N <= 128) {
    /* compiler-rt, at 128 bits */
    unsigned __int128 v;
    if (sgn) { /* __fixxfti */
      if (e < 0)
        v = 0;
      else if (e >= 128) {
        int pos = !f80_isnan(b) && !neg && !(eb == 0x7FFF && (b.m << 1) != 0);
        v = pos ? ((unsigned __int128)1 << 127) - 1 : (unsigned __int128)1 << 127;
      } else {
        unsigned __int128 m = b.m;
        m = e > 63 ? m << (e - 63) : m >> (63 - e);
        unsigned __int128 s = neg ? ~(unsigned __int128)0 : 0;
        v = (m ^ s) - s;
      }
    } else { /* __fixunsxfti */
      if (e < 0 || neg)
        v = 0;
      else if (e > 128)
        v = ~(unsigned __int128)0;
      else {
        unsigned __int128 m = b.m;
        v = e > 63 ? (e - 63 >= 128 ? 0 : m << (e - 63)) : m >> (63 - e);
      }
    }
    for (uint32_t i = 0; i < n; ++i) r[i] = (uint64_t)(v >> (64 * i));
    if (N % 64) r[n - 1] &= (UINT64_C(1) << (N % 64)) - 1;
    return conv_flags(b, 128, sgn);
  }
  /* N > 128: ExpandLargeFpConvert, the same code for fptosi and fptoui */
  if (eb == 0 || e < 0) {
    memset(r, 0, (size_t)n * sizeof *r);
  } else if (e >= (long)N) {
    memset(r, 0, (size_t)n * sizeof *r);
    if (!neg) { /* 2^(N-1) - 1 */
      for (uint32_t i = 0; i < n; ++i) r[i] = ~UINT64_C(0);
      if (N % 64) r[n - 1] &= (UINT64_C(1) << (N % 64)) - 1;
      r[(N - 1) / 64] &= ~(UINT64_C(1) << ((N - 1) % 64));
    } else {
      r[(N - 1) / 64] |= UINT64_C(1) << ((N - 1) % 64);
    }
  } else {
    f80_floor_mag(b, r, n);
    if (neg) mw_negate(r, n);
    if (N % 64) r[n - 1] &= (UINT64_C(1) << (N % 64)) - 1;
  }
  return conv_flags(b, N, sgn);
}

/* ---------------------------------------------------------------- integer -> f80 */

/* M (n words) rounded in place to its top p bits, to nearest even (the result may carry into one
 * more bit, an exact power of two). */
static void round_mag_ne(uint64_t *M, uint32_t n, uint32_t p) {
  uint32_t L = mw_bitlen(M, n);
  if (L <= p)
    return;
  long s = (long)(L - p);
  int guard = mw_bit(M, n, s - 1), sticky = mw_any_below(M, n, s - 1);
  int up = guard && (sticky || mw_bit(M, n, s));
  for (long i = 0; i < s; ++i) M[i / 64] &= ~(UINT64_C(1) << (i % 64));
  if (up)
    for (uint32_t w = (uint32_t)(s / 64), first = 1; w < n; ++w, first = 0) {
      uint64_t add = first ? UINT64_C(1) << (s % 64) : 1, old = M[w];
      M[w] += add;
      if (M[w] >= old)
        break;
    }
}

static f80b int_to_f80(const cqe_val *a, uint32_t N, int sgn, int rc, int *flags) {
  uint64_t *M = read_bits(a, N);
  uint32_t n = nwords(N);
  int neg = sgn && ((M[(N - 1) / 64] >> ((N - 1) % 64)) & 1);
  if (neg) {
    /* sign-extend to whole words, negate */
    if (N % 64) M[n - 1] |= ~((UINT64_C(1) << (N % 64)) - 1);
    mw_negate(M, n);
  }
  f80b r;
  if (mw_bitlen(M, n) == 0) {
    r.m = 0;
    r.se = 0;
  } else {
    uint64_t q;
    long lsb;
    int inf;
    *flags |= round_to(neg, M, n, 0, FMT_F80, rc, &q, &lsb, &inf);
    if (N > 128 && (sgn || !((M[(N - 1) / 64] >> ((N - 1) % 64)) & 1))) {
      /* LLVM 19 ExpandLargeFpConvert (expandIToFP) builds an fp128 in integer code, rounding |v|
       * to 113 bits to nearest even whatever the mode, then calls compiler-rt __trunctfxf2: two
       * roundings, the first adopted from LLVM (CR §2: which neighbour a double rounding lands on),
       * the second the library's, IEEE in the template's mode. The flags stay those of one IEEE
       * rounding (native raises none). uitofp with the top bit set is not LLVM 19's value at all
       * (a negative result, a miscompile): CR §2 (cq-cqcj) gives the non-negative value rounded
       * once at f80's 64-bit significand, in the template's mode for _rm (cq-6d9d, cq-xyqx), so
       * the single rounding above stands. */
      uint64_t *W = calloc(n + 1, sizeof *W); /* one word of headroom for the carry */
      if (!W) abort();
      memcpy(W, M, n * sizeof *W);
      round_mag_ne(W, n + 1, 113);
      round_to(neg, W, n + 1, 0, FMT_F80, rc, &q, &lsb, &inf);
      free(W);
    }
    r = f80_encode(neg, q, lsb, inf);
  }
  free(M);
  return r;
}

/* ---------------------------------------------------------------- fcmp */

/* LLVM fcmp predicate as (ordered-result bits: lt eq gt) | unordered bit. */
static int pred_code(const char *p) {
  static const struct {
    const char *n;
    int c;
  } t[] = {{"false", 0}, {"oeq", 2}, {"ogt", 4}, {"oge", 6}, {"olt", 1}, {"ole", 3}, {"one", 5}, {"ord", 7},
           {"uno", 8},   {"ueq", 10}, {"ugt", 12}, {"uge", 14}, {"ult", 9}, {"ule", 11}, {"une", 13}, {"true", 15}};
  for (size_t i = 0; i < sizeof t / sizeof t[0]; ++i)
    if (!strcmp(p, t[i].n)) return t[i].c;
  return -1;
}

/* ---------------------------------------------------------------- the op table */

typedef enum {
  K_BIN,     /* fadd fsub fmul fdiv frem */
  K_UN,      /* sqrt floor ceil trunc rint round */
  K_FMA,
  K_SIGN,    /* fneg fabs copysign */
  K_MINMAX,  /* fmax fmin */
  K_CMP,     /* fcmp fcmps */
  K_CLASS,   /* is_fpclass */
  K_FPEXT,
  K_FPTRUNC,
  K_ITOFP,   /* sitofp uitofp */
  K_FPTOI    /* fptosi fptoui */
} kind_t;

static const struct {
  const char *op;
  kind_t k;
  int nargs;
} OPS[] = {
    {"fadd", K_BIN, 2},     {"fsub", K_BIN, 2},     {"fmul", K_BIN, 2},       {"fdiv", K_BIN, 2},
    {"frem", K_BIN, 2},     {"sqrt", K_UN, 1},      {"floor", K_UN, 1},       {"ceil", K_UN, 1},
    {"trunc", K_UN, 1},     {"rint", K_UN, 1},      {"round", K_UN, 1},       {"fma", K_FMA, 3},
    {"fneg", K_SIGN, 1},    {"fabs", K_SIGN, 1},    {"copysign", K_SIGN, 2},  {"fmax", K_MINMAX, 2},
    {"fmin", K_MINMAX, 2},  {"fcmp", K_CMP, 2},     {"fcmps", K_CMP, 2},      {"is_fpclass", K_CLASS, 2},
    {"fpext", K_FPEXT, 1},  {"fptrunc", K_FPTRUNC, 1}, {"sitofp", K_ITOFP, 1}, {"uitofp", K_ITOFP, 1},
    {"fptosi", K_FPTOI, 1}, {"fptoui", K_FPTOI, 1},
};

static int find_op(const char *op) {
  for (size_t i = 0; i < sizeof OPS / sizeof OPS[0]; ++i)
    if (!strcmp(op, OPS[i].op)) return (int)i;
  return -1;
}

/* Does this template belong to the f80 family? */
static int is_f80_template(const cqe_tname *t) { return !strcmp(t->w, "f80") || !strcmp(t->to, "f80"); }

static long double un_op(const char *op, long double x) {
  if (!strcmp(op, "sqrt")) return sqrtl(x);
  if (!strcmp(op, "floor")) return floorl(x);
  if (!strcmp(op, "ceil")) return ceill(x);
  if (!strcmp(op, "trunc")) return truncl(x);
  if (!strcmp(op, "round")) return roundl(x);
  return rintl(x); /* rint: called in the template's mode (CR §2: the current mode, _rm/_rmq's) */
}

static long double bin_op(const char *op, long double a, long double b) {
  switch (op[1]) {
  case 'a': return a + b; /* fadd */
  case 's': return a - b; /* fsub */
  case 'm': return a * b; /* fmul */
  case 'd': return a / b; /* fdiv */
  default: return fmodl(a, b); /* frem: IEEE fmod, exact (CR §2) */
  }
}

static int f80_eval(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  if (!is_f80_template(t)) return CQE_OP_NOT_MINE;
  int oi = find_op(t->op);
  if (oi < 0) {
    cqe_fail("tmpl-f80: op %s is not an fp op", t->op);
    return -1;
  }
  kind_t k = OPS[oi].k;
  int ndata = OPS[oi].nargs;
  if (nargs != ndata + (t->rm ? 1 : 0)) {
    cqe_fail("tmpl-f80: %s_%s takes %d operands, got %d", t->op, t->w, ndata + (t->rm ? 1 : 0), nargs);
    return -1;
  }
  wid_t W, W2 = {0, 0};
  if (parse_wid(t->w, &W)) {
    cqe_fail("tmpl-f80: bad width '%s'", t->w);
    return -1;
  }
  int is_cast = k == K_FPEXT || k == K_FPTRUNC || k == K_ITOFP || k == K_FPTOI;
  if (is_cast) {
    if (parse_wid(t->to, &W2)) {
      cqe_fail("tmpl-f80: %s needs a target width, got '%s'", t->op, t->to);
      return -1;
    }
    int ok = (k == K_FPEXT && W.kind != 'i' && W.bits < 80 && W2.bits == 80 && W2.kind == 'f') ||
             (k == K_FPTRUNC && W.bits == 80 && W.kind == 'f' && W2.kind != 'i' && W2.bits < 80) ||
             (k == K_ITOFP && W.kind == 'i' && W2.kind == 'f' && W2.bits == 80) ||
             (k == K_FPTOI && W.kind == 'f' && W.bits == 80 && W2.kind == 'i');
    if (!ok) {
      cqe_fail("tmpl-f80: bad cast %s_%s_to_%s", t->op, t->w, t->to);
      return -1;
    }
  } else if (t->to[0]) {
    cqe_fail("tmpl-f80: %s takes no _to_", t->op);
    return -1;
  }
  int pc = 0;
  if (k == K_CMP) {
    pc = pred_code(t->pred);
    if (pc < 0) {
      cqe_fail("tmpl-f80: bad fcmp predicate '%s'", t->pred);
      return -1;
    }
  } else if (t->pred[0]) {
    cqe_fail("tmpl-f80: %s takes no predicate", t->op);
    return -1;
  }
  /* the template's mode for _rm/_rmq; plain rint reads the host's current mode (CR §2 rint row) */
  int rc = t->rm ? rc_of((uint32_t)word(&args[nargs - 1], 0)) : !strcmp(t->op, "rint") ? fegetround() : FE_TONEAREST;

  uint32_t rbits = 80;
  char rkind = 'f';
  if (k == K_CMP || k == K_CLASS) {
    rbits = 1;
    rkind = 'i';
  } else if (is_cast) {
    rbits = W2.bits;
    rkind = W2.kind;
  }
  /* Result scratch: up to nwords(rbits) words. */
  uint32_t rn = nwords(rbits);
  uint64_t *res = calloc(rn ? rn : 1, sizeof *res);
  if (!res) abort();
  int exc = 0;
  fpu_t f;

  switch (k) {
  case K_BIN:
  case K_UN:
  case K_FMA: {
    f80b in[3];
    int bad = 0;
    for (int i = 0; i < ndata; ++i) {
      in[i] = f80_of_val(&args[i]);
      bad |= f80_noncanonical(in[i]);
    }
    f80b r;
    if (bad) {
      r = F80_INDEF;
      exc = X_INVALID;
    } else {
      fpu_enter(&f, rc);
      long double v;
      if (k == K_BIN)
        v = bin_op(t->op, ld_of(in[0]), ld_of(in[1]));
      else if (k == K_UN)
        v = un_op(t->op, ld_of(in[0]));
      else
        v = fmal(ld_of(in[0]), ld_of(in[1]), ld_of(in[2]));
      exc = fpu_leave(&f);
      r = bits_of(v);
      /* CR §2 NaN row, normative over the x87 (larger-significand) and libm choices: the first
       * NaN operand in IR order, quieted; an invalid operation gives the real indefinite (the
       * f80 default NaN). A signaling NaN operand raises INVALID. */
      if (f80_isnan(r)) {
        int first = -1;
        for (int i = 0; i < ndata && first < 0; ++i)
          if (f80_isnan(in[i])) first = i;
        if (first >= 0) {
          r = in[first];
          r.m |= UINT64_C(1) << 62;
        } else {
          r = F80_INDEF;
        }
      }
      for (int i = 0; i < ndata; ++i)
        if (f80_isnan(in[i]) && !((in[i].m >> 62) & 1)) exc |= X_INVALID;
    }
    res[0] = r.m;
    res[1] = r.se;
    break;
  }
  case K_SIGN: {
    f80b a = f80_of_val(&args[0]);
    if (t->op[1] == 'n') /* fneg */
      a.se ^= 0x8000;
    else if (t->op[1] == 'a') /* fabs */
      a.se &= 0x7FFF;
    else /* copysign: magnitude of arg 0, sign of arg 1 */
      a.se = (uint16_t)((a.se & 0x7FFF) | (f80_of_val(&args[1]).se & 0x8000));
    res[0] = a.m;
    res[1] = a.se;
    break;
  }
  case K_MINMAX: {
    f80b a = f80_of_val(&args[0]), b = f80_of_val(&args[1]);
    f80b r;
    if (f80_noncanonical(a) || f80_noncanonical(b)) {
      r = F80_INDEF;
      exc = X_INVALID;
    } else {
      int ismax = t->op[2] == 'a';
      long double x = ld_of(a), y = ld_of(b);
      /* The value is CR §2's formula; the exception bits are IEEE maxNum/minNum, normative over
       * the libm call LLVM emits (CR §2, cq-qx1): INVALID iff a signaling NaN operand. */
      exc = (f80_isnan(a) && !((a.m >> 62) & 1)) || (f80_isnan(b) && !((b.m >> 62) & 1)) ? X_INVALID : 0;
      if (f80_isnan(a))
        r = b;
      else if (f80_isnan(b))
        r = a;
      else
        r = (ismax ? __builtin_isgreater(y, x) : __builtin_isless(y, x)) ? b : a;
    }
    res[0] = r.m;
    res[1] = r.se;
    break;
  }
  case K_CMP: {
    f80b a = f80_of_val(&args[0]), b = f80_of_val(&args[1]);
    int rel; /* 1 lt, 2 eq, 4 gt, 8 unordered */
    if (pc == 0 || pc == 15) {
      rel = 8; /* false/true read no operand and raise nothing (LLVM folds them) */
    } else if (f80_noncanonical(a) || f80_noncanonical(b)) {
      rel = 8;
      exc = X_INVALID;
    } else {
      long double x = ld_of(a), y = ld_of(b);
      fpu_enter(&f, rc);
      if (__builtin_isunordered(x, y))
        rel = 8;
      else if (x == y)
        rel = 2;
      else if (__builtin_isless(x, y))
        rel = 1;
      else
        rel = 4;
      exc = fpu_leave(&f);
      if (!strcmp(t->op, "fcmps") && rel == 8) exc |= X_INVALID; /* signaling: INVALID iff a NaN */
    }
    res[0] = (pc & rel) ? 1 : 0;
    break;
  }
  case K_CLASS: {
    /* Pure bit test (CR §2), LLVM's class bits. Pseudo-denormals read as denormals; the
     * non-canonical encodings are an invalid operand, i.e. the real indefinite: a quiet NaN. */
    f80b a = f80_of_val(&args[0]);
    uint32_t mask = (uint32_t)word(&args[1], 0);
    unsigned eb = a.se & 0x7FFF;
    int neg = a.se >> 15;
    int cls;
    if (f80_noncanonical(a))
      cls = 1;
    else if (eb == 0x7FFF)
      cls = (a.m << 1) == 0 ? (neg ? 2 : 9) : (((a.m >> 62) & 1) ? 1 : 0);
    else if (eb == 0)
      cls = a.m == 0 ? (neg ? 5 : 6) : (neg ? 4 : 7);
    else
      cls = neg ? 3 : 8;
    res[0] = (mask >> cls) & 1;
    break;
  }
  case K_FPEXT: {
    long double v;
    uint64_t bitsv = word(&args[0], 0);
    fpu_enter(&f, rc);
    if (W.bits == 64) {
      double d;
      memcpy(&d, &bitsv, 8);
      v = (long double)d;
    } else {
      /* bf16 is the top half of a binary32 (exact, a signaling NaN stays signaling) */
      uint32_t u = W.bits == 32   ? (uint32_t)bitsv
                   : W.kind == 'b' ? (uint32_t)(uint16_t)bitsv << 16
                                   : f16_to_f32_bits((uint16_t)bitsv);
      float s;
      memcpy(&s, &u, 4);
      v = (long double)s;
    }
    exc = fpu_leave(&f);
    f80b r = bits_of(v);
    res[0] = r.m;
    res[1] = r.se;
    break;
  }
  case K_FPTRUNC: {
    f80b a = f80_of_val(&args[0]);
    if (f80_noncanonical(a)) {
      a = F80_INDEF;
      exc = X_INVALID;
    }
    if (W2.bits == 16) {
      res[0] = f80_to_narrow(W2.kind == 'b' ? &N_BF16 : &N_F16, a, rc, &exc);
    } else {
      long double x = ld_of(a);
      fpu_enter(&f, rc);
      if (W2.bits == 64) {
        volatile double d = (double)x;
        double dd = d;
        memcpy(&res[0], &dd, 8);
      } else {
        volatile float s = (float)x;
        float ss = s;
        uint32_t u;
        memcpy(&u, &ss, 4);
        res[0] = u;
      }
      exc |= fpu_leave(&f);
    }
    break;
  }
  case K_ITOFP: {
    f80b r = int_to_f80(&args[0], W.bits, t->op[0] == 's', rc, &exc);
    res[0] = r.m;
    res[1] = r.se;
    break;
  }
  case K_FPTOI: {
    f80b a = f80_of_val(&args[0]);
    int inv = 0;
    if (f80_noncanonical(a)) {
      a = F80_INDEF;
      inv = X_INVALID;
    }
    exc = fix_int(a, W2.bits, t->op[4] == 's', res) | inv;
    break;
  }
  }

  if (t->exc) {
    rbits = 32;
    rkind = 'i';
  }
  if (out_begin(out, rbits, rkind)) {
    free(res);
    return -1;
  }
  if (t->exc)
    out->w[0] = (uint64_t)(uint32_t)exc;
  else
    for (uint32_t i = 0; i < rn; ++i) out->w[i] = res[i];
  free(res);
  return 0;
}

__attribute__((constructor)) static void tmpl_f80_register(void) {
  for (size_t i = 0; i < sizeof OPS / sizeof OPS[0]; ++i) cqe_register_op(OPS[i].op, f80_eval);
}
