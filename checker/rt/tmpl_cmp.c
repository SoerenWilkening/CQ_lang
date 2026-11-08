/* Template family: compare, select, min/max, abs, overflow, saturation (cq-w0-tmpl-cmp).
 *
 * Ops: icmp select smax smin umax umin abs {u,s}{add,sub,mul}_overflow {u,s}{add,sub}_sat.
 * Semantics: CONSTRUCTION_RULES §1.2 and §2 (normative), BACKEND_ABI §2.4, §2.5 and §2.7. Every
 * operation is generic over the width: values are little-endian 64-bit words, any N >= 1.
 *
 * Calling convention of each cqe_op_fn here (what the core dispatcher hands a family):
 *   - tname: the parsed template name. tname->w gives the operand width W (i<N>, f16, bf16, f32,
 *     f64, f80; select is the only op here that accepts an fp W, and copies its bit pattern).
 *     tname->pred is the icmp predicate. Shape, unc and the other fields do not change the value:
 *     the forward and the _unc twin are the same XOR map (BACKEND_ABI §2.1), and the dispatcher
 *     XORs the value into the out rail.
 *   - args: the DATA operands in signature order, handles already resolved to their basis values
 *     and literals as values: icmp, min/max, overflow, sat: (a, b); abs: (a); select: (c, arm1,
 *     arm2), c the i1 condition. Only the low W bits of an operand are read (a narrow literal or a
 *     signext/zeroext handle is read as its low W bits, CR §1.2); words beyond args[i].nw read 0.
 *   - out (cqe.h M1): owned by the dispatcher, non-NULL, zeroed, with bits, kind and nw =
 *     ceil(bits/64) preset to the result type (i1 'i' for icmp and *_overflow; W and W's kind
 *     otherwise). The handler checks the preset against the template (out_words(), the one place
 *     the buffer is touched for size) and writes the value with bits above out->bits zero; it
 *     never changes out->bits, out->kind, out->nw or out->w.
 *   - return (cqe.h M1): 0 when out holds the value; CQE_OP_NOT_MINE, decided from tname alone,
 *     with no cqe_fail, for an op outside this family; -1 after cqe_fail on a malformed call (bad
 *     width, arity or predicate, an out preset that does not match the template).
 */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"


typedef struct {
  uint32_t bits; /* W */
  char kind;     /* 'i' or 'f' */
  uint32_t nw;   /* ceil(W / 64) */
} width_t;

static int parse_width(const char *s, width_t *out) {
  if (!strcmp(s, "bf16")) { /* CR §1.1: bfloat16, a 16-bit fp bit pattern */
    out->bits = 16;
    out->kind = 'f';
    out->nw = 1;
    return 0;
  }
  char k = s[0];
  if (k != 'i' && k != 'f') return -1;
  if (s[1] < '1' || s[1] > '9') return -1;
  unsigned long n = 0;
  for (const char *p = s + 1; *p; ++p) {
    if (*p < '0' || *p > '9') return -1;
    n = n * 10 + (unsigned long)(*p - '0');
    if (n > (1ul << 24)) return -1;
  }
  if (k == 'f' && n != 16 && n != 32 && n != 64 && n != 80) return -1;
  out->bits = (uint32_t)n;
  out->kind = k;
  out->nw = (uint32_t)((n + 63) / 64);
  return 0;
}

/* ---- multi-word helpers over nw words, value bits W ---- */

static void mask_top(uint64_t *x, uint32_t nw, uint32_t bits) {
  uint32_t r = bits % 64;
  if (r) x[nw - 1] &= (UINT64_C(1) << r) - 1;
}

/* Load the low W bits of v into x[0..nw). */
static void load(uint64_t *x, const cqe_val *v, width_t W) {
  for (uint32_t i = 0; i < W.nw; ++i) x[i] = (v->w && i < v->nw) ? v->w[i] : 0;
  mask_top(x, W.nw, W.bits);
}

static int bit(const uint64_t *x, uint32_t i) { return (int)((x[i / 64] >> (i % 64)) & 1); }
static int sign(const uint64_t *x, width_t W) { return bit(x, W.bits - 1); }

static int is_zero(const uint64_t *x, uint32_t nw) {
  for (uint32_t i = 0; i < nw; ++i)
    if (x[i]) return 0;
  return 1;
}

/* Unsigned compare: -1, 0, 1. */
static int ucmp(const uint64_t *a, const uint64_t *b, uint32_t nw) {
  for (uint32_t i = nw; i-- > 0;) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return 0;
}

/* Signed (two's complement at W) compare. */
static int scmp(const uint64_t *a, const uint64_t *b, width_t W) {
  int sa = sign(a, W), sb = sign(b, W);
  if (sa != sb) return sa ? -1 : 1;
  return ucmp(a, b, W.nw);
}

/* r = a + b mod 2^W; returns the carry out of bit W-1. r may alias a or b. */
static int add(uint64_t *r, const uint64_t *a, const uint64_t *b, width_t W) {
  unsigned __int128 c = 0;
  for (uint32_t i = 0; i < W.nw; ++i) {
    c += (unsigned __int128)a[i] + b[i];
    r[i] = (uint64_t)c;
    c >>= 64;
  }
  uint32_t rem = W.bits % 64;
  int carry;
  if (rem) {
    carry = (int)((r[W.nw - 1] >> rem) & 1);
    mask_top(r, W.nw, W.bits);
  } else {
    carry = (int)c;
  }
  return carry;
}

/* r = a - b mod 2^W. r may alias a or b. */
static void sub(uint64_t *r, const uint64_t *a, const uint64_t *b, width_t W) {
  uint64_t borrow = 0;
  for (uint32_t i = 0; i < W.nw; ++i) {
    uint64_t ai = a[i], bi = b[i];
    uint64_t d = ai - bi - borrow;
    borrow = (ai < bi) || (ai == bi && borrow) ? 1 : 0;
    r[i] = d;
  }
  mask_top(r, W.nw, W.bits);
}

/* r = -a mod 2^W. */
static void neg(uint64_t *r, const uint64_t *a, width_t W, uint64_t *zero) {
  memset(zero, 0, W.nw * sizeof(uint64_t));
  sub(r, zero, a, W);
}

/* p[0..2nw) = a * b, the exact product of two nw-word unsigned numbers. */
static void mul_full(uint64_t *p, const uint64_t *a, const uint64_t *b, uint32_t nw) {
  memset(p, 0, 2 * nw * sizeof(uint64_t));
  for (uint32_t i = 0; i < nw; ++i) {
    unsigned __int128 c = 0;
    for (uint32_t j = 0; j < nw; ++j) {
      c += (unsigned __int128)a[i] * b[j] + p[i + j];
      p[i + j] = (uint64_t)c;
      c >>= 64;
    }
    p[i + nw] = (uint64_t)c;
  }
}

/* Is the 2nw-word number p >= 2^k? */
static int ge_pow2(const uint64_t *p, uint32_t pw, uint32_t k) {
  uint32_t wi = k / 64, bi = k % 64;
  if (wi >= pw) return 0;
  if (p[wi] >> bi) return 1;
  for (uint32_t i = wi + 1; i < pw; ++i)
    if (p[i]) return 1;
  return 0;
}

/* Is p == 2^k exactly? */
static int eq_pow2(const uint64_t *p, uint32_t pw, uint32_t k) {
  uint32_t wi = k / 64, bi = k % 64;
  if (wi >= pw) return 0;
  for (uint32_t i = 0; i < pw; ++i) {
    uint64_t want = i == wi ? (UINT64_C(1) << bi) : 0;
    if (p[i] != want) return 0;
  }
  return 1;
}

/* ---- out ---- */

/* The out buffer belongs to the dispatcher (cqe.h M1). Returns 0 when its preset matches the
 * result type this template implies. */
static int out_words(const cqe_val *out, uint32_t need, uint32_t bits, char kind) {
  if (!out->w || out->bits != bits || out->kind != kind || out->nw != need) {
    cqe_fail("tmpl_cmp: out preset %u-bit '%c' in %u words, the template's result is %u-bit '%c'",
             out->bits, out->kind ? out->kind : '?', out->nw, bits, kind);
    return -1;
  }
  return 0;
}

static int put(cqe_val *out, const uint64_t *x, uint32_t bits, char kind) {
  uint32_t need = (bits + 63) / 64;
  if (out_words(out, need, bits, kind)) return -1;
  memcpy(out->w, x, need * sizeof(uint64_t));
  mask_top(out->w, need, bits);
  return 0;
}

static int put_i1(cqe_val *out, int b) {
  uint64_t x = b ? 1 : 0;
  return put(out, &x, 1, 'i');
}

/* ---- dispatch ---- */

enum op_t {
  OP_ICMP, OP_SELECT, OP_SMAX, OP_SMIN, OP_UMAX, OP_UMIN, OP_ABS,
  OP_UADDO, OP_SADDO, OP_USUBO, OP_SSUBO, OP_UMULO, OP_SMULO, OP_UADDSAT, OP_USUBSAT, OP_SADDSAT, OP_SSUBSAT
};

static const struct { const char *name; enum op_t op; int nargs; } OPS[] = {
    {"icmp", OP_ICMP, 2},           {"select", OP_SELECT, 3},
    {"smax", OP_SMAX, 2},           {"smin", OP_SMIN, 2},
    {"umax", OP_UMAX, 2},           {"umin", OP_UMIN, 2},
    {"abs", OP_ABS, 1},             {"uadd_overflow", OP_UADDO, 2},
    {"sadd_overflow", OP_SADDO, 2}, {"usub_overflow", OP_USUBO, 2},
    {"ssub_overflow", OP_SSUBO, 2}, {"umul_overflow", OP_UMULO, 2},
    {"smul_overflow", OP_SMULO, 2}, {"uadd_sat", OP_UADDSAT, 2},
    {"usub_sat", OP_USUBSAT, 2}, {"sadd_sat", OP_SADDSAT, 2}, {"ssub_sat", OP_SSUBSAT, 2},
};
#define NOPS (sizeof OPS / sizeof OPS[0])

static int icmp(const char *pred, const uint64_t *a, const uint64_t *b, width_t W, int *res) {
  int u = ucmp(a, b, W.nw), s = scmp(a, b, W);
  if (!strcmp(pred, "eq")) *res = u == 0;
  else if (!strcmp(pred, "ne")) *res = u != 0;
  else if (!strcmp(pred, "ugt")) *res = u > 0;
  else if (!strcmp(pred, "uge")) *res = u >= 0;
  else if (!strcmp(pred, "ult")) *res = u < 0;
  else if (!strcmp(pred, "ule")) *res = u <= 0;
  else if (!strcmp(pred, "sgt")) *res = s > 0;
  else if (!strcmp(pred, "sge")) *res = s >= 0;
  else if (!strcmp(pred, "slt")) *res = s < 0;
  else if (!strcmp(pred, "sle")) *res = s <= 0;
  else return -1;
  return 0;
}

static int eval(enum op_t op, const cqe_tname *t, const cqe_val *args, width_t W, cqe_val *out,
                uint64_t *a, uint64_t *b, uint64_t *r, uint64_t *p) {
  if (op == OP_SELECT) {
    width_t I1 = {1, 'i', 1};
    uint64_t c;
    load(&c, &args[0], I1);
    load(r, c ? &args[1] : &args[2], W);
    return put(out, r, W.bits, W.kind);
  }
  if (W.kind != 'i') {
    cqe_fail("tmpl_cmp: %s takes an integer width, got %s", t->op, t->w);
    return -1;
  }
  load(a, &args[0], W);
  if (op != OP_ABS) load(b, &args[1], W);
  switch (op) {
  case OP_ICMP: {
    int res;
    if (icmp(t->pred, a, b, W, &res)) {
      cqe_fail("tmpl_cmp: unknown icmp predicate '%s'", t->pred);
      return -1;
    }
    return put_i1(out, res);
  }
  case OP_SMAX: return put(out, scmp(a, b, W) >= 0 ? a : b, W.bits, 'i');
  case OP_SMIN: return put(out, scmp(a, b, W) <= 0 ? a : b, W.bits, 'i');
  case OP_UMAX: return put(out, ucmp(a, b, W.nw) >= 0 ? a : b, W.bits, 'i');
  case OP_UMIN: return put(out, ucmp(a, b, W.nw) <= 0 ? a : b, W.bits, 'i');
  case OP_ABS: /* CR §2: abs(INT_MIN) = INT_MIN, which -a mod 2^W gives */
    if (sign(a, W)) {
      neg(r, a, W, b);
      return put(out, r, W.bits, 'i');
    }
    return put(out, a, W.bits, 'i');
  case OP_UADDO: return put_i1(out, add(r, a, b, W));
  case OP_SADDO: {
    int sa = sign(a, W), sb = sign(b, W);
    add(r, a, b, W);
    return put_i1(out, sa == sb && sign(r, W) != sa);
  }
  case OP_USUBO: return put_i1(out, ucmp(a, b, W.nw) < 0);
  case OP_SSUBO: {
    int sa = sign(a, W), sb = sign(b, W);
    sub(r, a, b, W);
    return put_i1(out, sa != sb && sign(r, W) != sa);
  }
  case OP_UMULO:
    mul_full(p, a, b, W.nw);
    return put_i1(out, ge_pow2(p, 2 * W.nw, W.bits));
  case OP_SMULO: {
    /* |a|·|b| exactly (as unsigned W-bit magnitudes; |INT_MIN| = 2^(W-1) fits unsigned W). The
     * product fits iff it is <= 2^(W-1) - 1 when positive, <= 2^(W-1) when negative. */
    int sa = sign(a, W), sb = sign(b, W);
    if (sa) neg(a, a, W, r);
    if (sb) neg(b, b, W, r);
    mul_full(p, a, b, W.nw);
    uint32_t pw = 2 * W.nw, k = W.bits - 1;
    int negative = (sa != sb) && !is_zero(p, pw);
    int ovf = negative ? (ge_pow2(p, pw, k) && !eq_pow2(p, pw, k)) : ge_pow2(p, pw, k);
    return put_i1(out, ovf);
  }
  case OP_UADDSAT:
    if (add(r, a, b, W)) {
      memset(r, 0xff, W.nw * sizeof(uint64_t));
      mask_top(r, W.nw, W.bits);
    }
    return put(out, r, W.bits, 'i');
  case OP_USUBSAT:
    if (ucmp(a, b, W.nw) < 0) memset(r, 0, W.nw * sizeof(uint64_t));
    else sub(r, a, b, W);
    return put(out, r, W.bits, 'i');
  case OP_SADDSAT:
  case OP_SSUBSAT: {   /* BACKEND_ABI §2.7: signed a ± b clamped to [-2^(W-1), 2^(W-1)-1] */
    int sa = sign(a, W), sb = sign(b, W), isadd = op == OP_SADDSAT;
    if (isadd) add(r, a, b, W); else sub(r, a, b, W);
    if ((isadd ? sa == sb : sa != sb) && sign(r, W) != sa) {
      uint32_t k = W.bits - 1;
      memset(r, sa ? 0 : 0xff, W.nw * sizeof(uint64_t));
      mask_top(r, W.nw, W.bits);
      if (sa) r[k / 64] |= 1ULL << (k % 64); else r[k / 64] &= ~(1ULL << (k % 64));
    }
    return put(out, r, W.bits, 'i');
  }
  default: break;
  }
  cqe_fail("tmpl_cmp: internal: op %s not dispatched", t->op);
  return -1;
}

static int tmpl_cmp_op(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  size_t k = 0;
  while (k < NOPS && strcmp(OPS[k].name, t->op)) ++k;
  if (k == NOPS) return CQE_OP_NOT_MINE;
  if (nargs != OPS[k].nargs) {
    cqe_fail("tmpl_cmp: %s takes %d data operands, got %d", t->op, OPS[k].nargs, nargs);
    return -1;
  }
  if (OPS[k].op != OP_ICMP && t->pred[0]) {
    cqe_fail("tmpl_cmp: %s takes no predicate, got '%s'", t->op, t->pred);
    return -1;
  }
  if (t->to[0]) {
    cqe_fail("tmpl_cmp: %s takes no _to_ width, got '%s'", t->op, t->to);
    return -1;
  }
  width_t W;
  if (parse_width(t->w, &W)) {
    cqe_fail("tmpl_cmp: bad width '%s' in %s", t->w, t->op);
    return -1;
  }
  /* a, b, r: W.nw words each; p: 2 W.nw words (the full product). */
  uint64_t small[10] = {0}; /* cq-9hzgh: up to two words need no allocation */
  uint64_t *buf = W.nw <= 2 ? small : calloc(5 * (size_t)W.nw, sizeof(uint64_t));
  if (!buf) {
    cqe_fail("tmpl_cmp: out of memory at %s", t->w);
    return -1;
  }
  int rc = eval(OPS[k].op, t, args, W, out, buf, buf + W.nw, buf + 2 * W.nw, buf + 3 * W.nw);
  if (buf != small)
    free(buf);
  return rc;
}

__attribute__((constructor)) static void tmpl_cmp_register(void) {
  for (size_t k = 0; k < NOPS; ++k) cqe_register_op(OPS[k].name, tmpl_cmp_op);
}
