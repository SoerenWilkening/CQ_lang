/* Template family: integer arithmetic and casts (cq-w0-tmpl-int).
 *
 *   add sub mul udiv sdiv urem srem    at any width i<N>
 *   zext sext trunc (with _to_)        any i<N> -> i<M>
 *   bitcast                            any W -> W2 of equal bit count (f64<->i64, f80<->i80, bf16<->i16, ...)
 *
 * Semantics: CONSTRUCTION_RULES §2 (wins) and BACKEND_ABI §2.2, §2.3, §2.6. Integers are unsigned
 * mod 2^N unless the op is signed. §2 totalization rows implemented here:
 *   udiv(a, 0) = 2^N - 1          urem(a, 0) = a
 *   sdiv(a, 0) = a >= 0 ? -1 : +1 srem(a, 0) = a
 *   sdiv(INT_MIN, -1) = INT_MIN   srem(INT_MIN, -1) = 0
 *
 * and, or and xor (every width, the i1 data templates of flags included) belong to tmpl-bits
 * (checker/rt/tmpl_bits.c), by owner ruling on bead cq-f69; this family does not register them.
 *
 * Generic multi-word code over little-endian 64-bit words; no per-width tables.
 *
 * Handler convention: M1 in cqe.h (freeze bead cq-mgi) governs; in its terms:
 *   return 0: out computed; CQE_OP_NOT_MINE: not this family's template (trunc without _to_ is the
 *   fp rounding op of tmpl-fpmisc/tmpl-f80); -1: cqe_fail was called (malformed operands).
 *   out: the dispatcher presets out->w, bits, kind and nw; bits, kind and nw are rewritten here to
 *   the same values. (out->w NULL on entry, which the real dispatcher never passes, is calloc'ed.) Bits above `bits` are zero. The forward value is computed regardless of
 *   tname->unc (forward and _unc are the same XOR map, BACKEND_ABI §2.1). */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

#define CQE_OP_NOT_MINE 1

typedef struct { char kind; uint32_t bits; } tw_;

static uint32_t nwords_(uint32_t bits) { return (bits + 63u) / 64u; }

/* "i<N>" | "f16" | "f32" | "f64" | "f80" | "bf16". Returns 0 on a malformed width. bf16 is kind 'f'
 * bits 16 like f16 (cqe.h M2); only bitcast reaches it here (bf16<->i16, bf16<->f16: abi's Dom::Bitcast
 * takes equal bits of different kinds, and BFloat is its own kind), and a bitcast copies the bits. */
static int parse_width_(const char *s, tw_ *out) {
  if (s[0] == 'i') {
    if (s[1] < '1' || s[1] > '9') return 0;
    uint64_t n = 0;
    for (const char *p = s + 1; *p; ++p) {
      if (*p < '0' || *p > '9') return 0;
      n = n * 10 + (uint64_t)(*p - '0');
      if (n > (1u << 23)) return 0; /* LLVM's maximum integer width */
    }
    out->kind = 'i'; out->bits = (uint32_t)n;
    return 1;
  }
  if (s[0] == 'f') {
    if (!strcmp(s, "f16")) { out->kind = 'f'; out->bits = 16; return 1; }
    if (!strcmp(s, "f32")) { out->kind = 'f'; out->bits = 32; return 1; }
    if (!strcmp(s, "f64")) { out->kind = 'f'; out->bits = 64; return 1; }
    if (!strcmp(s, "f80")) { out->kind = 'f'; out->bits = 80; return 1; }
  }
  if (!strcmp(s, "bf16")) { out->kind = 'f'; out->bits = 16; return 1; }
  return 0;
}

/* ---- multi-word helpers; every buffer has n = nwords_(bits) words ---- */

static void mask_top_(uint64_t *w, uint32_t bits) {
  uint32_t n = nwords_(bits), r = bits % 64u;
  if (r) w[n - 1] &= (UINT64_C(1) << r) - 1u;
}

static int bit_(const uint64_t *w, uint32_t i) { return (int)((w[i / 64u] >> (i % 64u)) & 1u); }

static int is_zero_(const uint64_t *w, uint32_t n) {
  for (uint32_t i = 0; i < n; ++i)
    if (w[i]) return 0;
  return 1;
}

static int eq_(const uint64_t *a, const uint64_t *b, uint32_t n) {
  return memcmp(a, b, (size_t)n * sizeof(uint64_t)) == 0;
}

/* a >= b, unsigned */
static int uge_(const uint64_t *a, const uint64_t *b, uint32_t n) {
  for (uint32_t i = n; i-- > 0;)
    if (a[i] != b[i]) return a[i] > b[i];
  return 1;
}

static void add_(uint64_t *o, const uint64_t *a, const uint64_t *b, uint32_t n) {
  uint64_t c = 0;
  for (uint32_t i = 0; i < n; ++i) {
    uint64_t s = a[i] + c, c1 = s < c;
    uint64_t t = s + b[i], c2 = t < s;
    o[i] = t; c = c1 | c2;
  }
}

static void sub_(uint64_t *o, const uint64_t *a, const uint64_t *b, uint32_t n) {
  uint64_t br = 0;
  for (uint32_t i = 0; i < n; ++i) {
    uint64_t d = a[i] - b[i], b1 = a[i] < b[i];
    uint64_t e = d - br, b2 = d < br;
    o[i] = e; br = b1 | b2;
  }
}

/* o = a * b mod 2^(64n); o must not alias a or b */
static void mul_(uint64_t *o, const uint64_t *a, const uint64_t *b, uint32_t n) {
  memset(o, 0, (size_t)n * sizeof(uint64_t));
  for (uint32_t i = 0; i < n; ++i) {
    unsigned __int128 carry = 0;
    for (uint32_t j = 0; i + j < n; ++j) {
      unsigned __int128 t = (unsigned __int128)a[i] * b[j] + o[i + j] + carry;
      o[i + j] = (uint64_t)t; carry = t >> 64;
    }
  }
}

/* two's-complement negation mod 2^bits */
static void neg_(uint64_t *o, const uint64_t *a, uint32_t bits) {
  uint32_t n = nwords_(bits);
  uint64_t c = 1;
  for (uint32_t i = 0; i < n; ++i) {
    uint64_t t = ~a[i] + c;
    c = (c && t == 0);
    o[i] = t;
  }
  mask_top_(o, bits);
}

/* q = a / b, r = a % b, unsigned, b != 0. Restoring division, one bit per step. */
static void udivrem_(uint64_t *q, uint64_t *r, const uint64_t *a, const uint64_t *b, uint32_t bits) {
  uint32_t n = nwords_(bits);
  memset(q, 0, (size_t)n * sizeof(uint64_t));
  memset(r, 0, (size_t)n * sizeof(uint64_t));
  /* After j steps r < 2^j, so the shift before step j+1 <= bits never leaves the word array. */
  for (uint32_t i = bits; i-- > 0;) {
    for (uint32_t k = n - 1; k > 0; --k) r[k] = (r[k] << 1) | (r[k - 1] >> 63);
    r[0] = (r[0] << 1) | (uint64_t)bit_(a, i);
    if (uge_(r, b, n)) {
      sub_(r, r, b, n);
      q[i / 64u] |= UINT64_C(1) << (i % 64u);
    }
  }
}

static void all_ones_(uint64_t *o, uint32_t bits) {
  memset(o, 0xff, (size_t)nwords_(bits) * sizeof(uint64_t));
  mask_top_(o, bits);
}

static void int_min_(uint64_t *o, uint32_t bits) {
  memset(o, 0, (size_t)nwords_(bits) * sizeof(uint64_t));
  o[(bits - 1) / 64u] = UINT64_C(1) << ((bits - 1) % 64u);
}

/* ---- operand access ---- */

static int read_arg_(const char *sym_op, const cqe_val *v, tw_ t, uint64_t *dst) {
  if (v->bits != t.bits || v->kind != t.kind || !v->w || v->nw < nwords_(t.bits)) {
    cqe_fail("tmpl_int: %s: operand is %c%u (nw %u), expected %c%u", sym_op, v->kind ? v->kind : '?',
             v->bits, v->nw, t.kind, t.bits);
    return 0;
  }
  memcpy(dst, v->w, (size_t)nwords_(t.bits) * sizeof(uint64_t));
  mask_top_(dst, t.bits); /* the backend reads only the low W bits (CR §1.2) */
  return 1;
}

static int write_out_(const char *sym_op, cqe_val *out, tw_ t, const uint64_t *src) {
  uint32_t n = nwords_(t.bits);
  if (!out->w) {
    out->w = (uint64_t *)calloc(n, sizeof(uint64_t));
    if (!out->w) { cqe_fail("tmpl_int: %s: out of memory", sym_op); return 0; }
  } else if (out->nw < n) {
    cqe_fail("tmpl_int: %s: result buffer of %u words, need %u", sym_op, out->nw, n);
    return 0;
  }
  memcpy(out->w, src, (size_t)n * sizeof(uint64_t));
  mask_top_(out->w, t.bits);
  out->bits = t.bits; out->kind = t.kind; out->nw = n;
  return 1;
}

enum { OP_ADD, OP_SUB, OP_MUL, OP_UDIV, OP_SDIV, OP_UREM, OP_SREM, OP_ZEXT, OP_SEXT, OP_TRUNC, OP_BITCAST, OP_NONE };

static int op_code_(const char *op) {
  static const char *const names[] = {"add", "sub", "mul",  "udiv",  "sdiv", "urem",
                                      "srem", "zext", "sext", "trunc", "bitcast"};
  for (int i = 0; i < OP_NONE; ++i)
    if (!strcmp(op, names[i])) return i;
  return OP_NONE;
}

static int binary_(int op, const char *name, tw_ t, const cqe_val *args, cqe_val *out) {
  uint32_t n = nwords_(t.bits), bits = t.bits;
  uint64_t small[12] = {0}; /* cq-9hzgh: a value of up to two words needs no allocation */
  uint64_t *buf = n <= 2 ? small : (uint64_t *)calloc((size_t)n * 6u, sizeof(uint64_t));
  if (!buf) { cqe_fail("tmpl_int: %s: out of memory", name); return -1; }
  uint64_t *a = buf, *b = buf + n, *o = buf + 2 * n, *t1 = buf + 3 * n, *t2 = buf + 4 * n,
           *t3 = buf + 5 * n;
  int ok = read_arg_(name, &args[0], t, a) && read_arg_(name, &args[1], t, b);
  if (ok) {
    switch (op) {
    case OP_ADD: add_(o, a, b, n); break;
    case OP_SUB: sub_(o, a, b, n); break;
    case OP_MUL: mul_(o, a, b, n); break;
    case OP_UDIV:
    case OP_UREM:
      if (is_zero_(b, n)) {
        if (op == OP_UDIV) all_ones_(o, bits);          /* udiv(a, 0) = 2^W - 1 */
        else memcpy(o, a, (size_t)n * sizeof(uint64_t)); /* urem(a, 0) = a */
      } else {
        udivrem_(t1, t2, a, b, bits);
        memcpy(o, op == OP_UDIV ? t1 : t2, (size_t)n * sizeof(uint64_t));
      }
      break;
    case OP_SDIV:
    case OP_SREM: {
      int sa = bit_(a, bits - 1), sb = bit_(b, bits - 1);
      if (is_zero_(b, n)) {
        if (op == OP_SREM) memcpy(o, a, (size_t)n * sizeof(uint64_t)); /* srem(a, 0) = a */
        else if (!sa) all_ones_(o, bits);                            /* sdiv(a>=0, 0) = -1 */
        else { memset(o, 0, (size_t)n * sizeof(uint64_t)); o[0] = 1; mask_top_(o, bits); } /* +1 */
        break;
      }
      int_min_(t3, bits);
      all_ones_(t1, bits);
      if (eq_(a, t3, n) && eq_(b, t1, n)) {
        if (op == OP_SDIV) memcpy(o, t3, (size_t)n * sizeof(uint64_t)); /* INT_MIN / -1 = INT_MIN */
        else memset(o, 0, (size_t)n * sizeof(uint64_t));               /* INT_MIN rem -1 = 0 */
        break;
      }
      /* |a| and |b| as unsigned W-bit values (|INT_MIN| = 2^(W-1) fits unsigned) */
      if (sa) neg_(a, a, bits);
      if (sb) neg_(b, b, bits);
      udivrem_(t1, t2, a, b, bits);
      if (op == OP_SDIV) { /* truncating: negative iff the signs differ */
        if (sa != sb) neg_(o, t1, bits);
        else memcpy(o, t1, (size_t)n * sizeof(uint64_t));
      } else {             /* remainder takes the sign of a */
        if (sa) neg_(o, t2, bits);
        else memcpy(o, t2, (size_t)n * sizeof(uint64_t));
      }
      break;
    }
    default: break;
    }
    ok = write_out_(name, out, t, o);
  }
  if (buf != small) free(buf);
  return ok ? 0 : -1;
}

static int cast_(int op, const char *name, tw_ from, tw_ to, const cqe_val *args, cqe_val *out) {
  uint32_t nf = nwords_(from.bits), nt = nwords_(to.bits);
  uint32_t nmax = nf > nt ? nf : nt;
  uint64_t sa[2] = {0}, so[2] = {0}; /* cq-9hzgh: up to two words need no allocation */
  uint64_t *a = nmax <= 2 ? sa : (uint64_t *)calloc(nmax, sizeof(uint64_t));
  uint64_t *o = nmax <= 2 ? so : (uint64_t *)calloc(nmax, sizeof(uint64_t));
  if (!a || !o) { if (a != sa) free(a); if (o != so) free(o); cqe_fail("tmpl_int: %s: out of memory", name); return -1; }
  int ok = 1;
  switch (op) {
  case OP_ZEXT:
  case OP_SEXT:
    if (from.kind != 'i' || to.kind != 'i' || to.bits <= from.bits) {
      cqe_fail("tmpl_int: %s: needs i<N> to a wider i<M>, got %c%u to %c%u", name, from.kind,
               from.bits, to.kind, to.bits);
      ok = 0;
    }
    break;
  case OP_TRUNC:
    if (from.kind != 'i' || to.kind != 'i' || to.bits >= from.bits) {
      cqe_fail("tmpl_int: %s: needs i<N> to a narrower i<M>, got %c%u to %c%u", name, from.kind,
               from.bits, to.kind, to.bits);
      ok = 0;
    }
    break;
  case OP_BITCAST:
    if (to.bits != from.bits) {
      cqe_fail("tmpl_int: %s: bit counts differ, %c%u to %c%u", name, from.kind, from.bits,
               to.kind, to.bits);
      ok = 0;
    }
    break;
  default: ok = 0; break;
  }
  if (ok) ok = read_arg_(name, &args[0], from, a); /* bits above from.bits are now zero */
  if (ok) {
    memcpy(o, a, (size_t)nmax * sizeof(uint64_t));
    if (op == OP_SEXT && bit_(a, from.bits - 1)) {
      for (uint32_t i = from.bits; i < nt * 64u; ++i) o[i / 64u] |= UINT64_C(1) << (i % 64u);
    }
    /* zext: zero fill is already there; trunc: write_out_ masks to to.bits; bitcast: same bits */
    ok = write_out_(name, out, to, o);
  }
  if (a != sa) free(a);
  if (o != so) free(o);
  return ok ? 0 : -1;
}

static int tmpl_int_op_(const cqe_tname *tn, const cqe_val *args, int nargs, cqe_val *out) {
  int op = op_code_(tn->op);
  if (op == OP_NONE) return CQE_OP_NOT_MINE;
  int is_cast = op >= OP_ZEXT;
  if (op == OP_TRUNC && tn->to[0] == '\0') return CQE_OP_NOT_MINE; /* fp rounding trunc */
  if (tn->pred[0] || tn->rm || tn->exc) {
    cqe_fail("tmpl_int: %s: no predicate, rounding mode or _exc is defined for this op",
             tn->op);
    return -1;
  }
  tw_ w, to;
  if (!parse_width_(tn->w, &w)) {
    cqe_fail("tmpl_int: %s: malformed width '%s'", tn->op, tn->w);
    return -1;
  }
  int arity = is_cast ? 1 : 2;
  if (nargs != arity) {
    cqe_fail("tmpl_int: %s_%s: %d operands, expected %d", tn->op, tn->w, nargs, arity);
    return -1;
  }
  if (tn->shape[0]) {
    size_t len = strlen(tn->shape);
    if ((int)len != arity || strspn(tn->shape, "hql") != len) {
      cqe_fail("tmpl_int: %s_%s: shape '%s' does not fit %d operands", tn->op, tn->w, tn->shape,
               arity);
      return -1;
    }
  }
  if (is_cast) {
    if (!tn->to[0] || !parse_width_(tn->to, &to)) {
      cqe_fail("tmpl_int: %s_%s: missing or malformed _to_ width '%s'", tn->op, tn->w, tn->to);
      return -1;
    }
    return cast_(op, tn->op, w, to, args, out);
  }
  if (tn->to[0] || w.kind != 'i') {
    cqe_fail("tmpl_int: %s_%s%s%s: an integer binary op takes one i<N> width", tn->op, tn->w,
             tn->to[0] ? "_to_" : "", tn->to);
    return -1;
  }
  return binary_(op, tn->op, w, args, out);
}

__attribute__((constructor)) static void tmpl_int_register_(void) {
  static const char *const ops[] = {"add",  "sub",  "mul",  "udiv",  "sdiv",   "urem",
                                    "srem", "zext", "sext", "trunc", "bitcast"};
  for (size_t i = 0; i < sizeof ops / sizeof ops[0]; ++i) cqe_register_op(ops[i], tmpl_int_op_);
}
