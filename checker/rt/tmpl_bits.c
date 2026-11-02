/* Checker template family: bitwise, shifts and bit counting (cq-w0-tmpl-bits).
 *
 * Evaluator semantics of the templates and, or, xor, shl, lshr, ashr, fshl, fshr, bswap, ctlz,
 * cttz, ctpop on basis values, per CONSTRUCTION_RULES §2 (wins) and BACKEND_ABI §2.3/§2.8:
 *   - integers are two's complement on W bits, any W >= 1, little-endian 64-bit words;
 *   - every operand is read as its low W bits (a narrow literal, CR §1.2);
 *   - shl/lshr/ashr and fshl/fshr take the amount mod W, the amount read unsigned at width W
 *     (CR §2, literal or quantum amount);
 *   - ctlz(0) = cttz(0) = W; the counts have width W;
 *   - bswap is byte reversal, defined for W a multiple of 16 (BACKEND_ABI §2.8, LLVM's domain);
 *   - bitreverse is bit reversal, any W (CR §1.2 since f684858).
 *
 * Handler convention: M1 in cqe.h (freeze bead cq-mgi). In short:
 *   - return 0: out computed; CQE_OP_NOT_MINE: not this family's template (no cqe_fail, out
 *     untouched); -1: malformed, cqe_fail already called. Every name this family registers is its
 *     own at every width, so it declines only an op name it does not know. (tmpl-int also
 *     registers and/or/xor; both compute the same total function, cq-f69.) Shapes (CR §1.2,
 *     every mix for fshl/fshr) need no handling: args arrive resolved in signature order.
 *   - the core owns the output: on entry out->w is non-NULL with out->nw = ceil(bits/64) words,
 *     zeroed, and out->bits/out->kind preset to the result type (i<W> for every op here). The
 *     handler writes the value into out->w (bits above W zero) and leaves bits/kind/nw alone.
 *   - args are every forward-call argument in signature order, literals included, resolved to
 *     values (bits = rail width or literal LLVM type width); the _unc form's out handle is not
 *     passed; the handler computes f(args) whatever tname->unc says and the core XORs it in.
 * All scratch storage goes through tb_alloc and is released before return.
 */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

#define TB_WBITS 64u

static uint32_t tb_nwords(uint32_t bits) { return (bits + TB_WBITS - 1) / TB_WBITS; }

static int tb_bit(const uint64_t *w, uint32_t i) { return (int)((w[i / TB_WBITS] >> (i % TB_WBITS)) & 1u); }

static void tb_setbit(uint64_t *w, uint32_t i, int v) {
  uint64_t m = (uint64_t)1 << (i % TB_WBITS);
  if (v)
    w[i / TB_WBITS] |= m;
  else
    w[i / TB_WBITS] &= ~m;
}

/* The width W of a template, from its name field ("i<N>"). 0 if malformed. */
static uint32_t tb_width(const cqe_tname *t) {
  if (t->w[0] != 'i' || t->w[1] < '1' || t->w[1] > '9')
    return 0;
  uint64_t n = 0;
  for (const char *p = t->w + 1; *p; ++p) {
    if (*p < '0' || *p > '9')
      return 0;
    n = n * 10 + (uint64_t)(*p - '0');
    if (n > (1u << 24))
      return 0;
  }
  return (uint32_t)n;
}

/* The one allocation helper: n zeroed scratch words (aborts on exhaustion; never NULL). */
static uint64_t *tb_alloc(uint32_t n) {
  uint64_t *r = calloc(n ? n : 1, sizeof *r);
  if (!r)
    abort();
  return r;
}

/* Copy the low W bits of v into a fresh zero-extended buffer of tb_nwords(W) words. */
static uint64_t *tb_read(const cqe_val *v, uint32_t W) {
  uint32_t nw = tb_nwords(W);
  uint64_t *r = tb_alloc(nw);
  uint32_t have = v->nw < nw ? v->nw : nw;
  if (have && v->w)
    memcpy(r, v->w, have * sizeof *r);
  if (W % TB_WBITS)
    r[nw - 1] &= ((uint64_t)1 << (W % TB_WBITS)) - 1;
  return r;
}

/* x mod W, x a W-bit unsigned value in tb_nwords(W) words. */
static uint32_t tb_mod(const uint64_t *x, uint32_t W) {
  unsigned __int128 r = 0;
  for (uint32_t i = tb_nwords(W); i-- > 0;)
    r = ((r << 64) | x[i]) % W;
  return (uint32_t)r;
}

/* r = (x << s) truncated to W bits; 0 <= s; r and x distinct. */
static void tb_shl(uint64_t *r, const uint64_t *x, uint32_t s, uint32_t W) {
  memset(r, 0, tb_nwords(W) * sizeof *r);
  for (uint32_t i = s; i < W; ++i)
    tb_setbit(r, i, tb_bit(x, i - s));
}

/* r = x >> s (logical when fill = 0, else the vacated bits take fill); r and x distinct. */
static void tb_shr(uint64_t *r, const uint64_t *x, uint32_t s, uint32_t W, int fill) {
  memset(r, 0, tb_nwords(W) * sizeof *r);
  for (uint32_t i = 0; i < W; ++i)
    tb_setbit(r, i, i + s < W ? tb_bit(x, i + s) : fill);
}

enum tb_op { TB_AND, TB_OR, TB_XOR, TB_SHL, TB_LSHR, TB_ASHR, TB_FSHL, TB_FSHR, TB_BSWAP, TB_BITREVERSE, TB_CTLZ, TB_CTTZ, TB_CTPOP };

static const struct {
  const char *name;
  enum tb_op op;
  int arity;
} tb_ops[] = {
    {"and", TB_AND, 2},   {"or", TB_OR, 2},     {"xor", TB_XOR, 2},     {"shl", TB_SHL, 2},
    {"lshr", TB_LSHR, 2}, {"ashr", TB_ASHR, 2}, {"fshl", TB_FSHL, 3},   {"fshr", TB_FSHR, 3},
    {"bswap", TB_BSWAP, 1}, {"bitreverse", TB_BITREVERSE, 1}, {"ctlz", TB_CTLZ, 1}, {"cttz", TB_CTTZ, 1}, {"ctpop", TB_CTPOP, 1},
};

static int tb_eval(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  int k = -1;
  for (size_t i = 0; i < sizeof tb_ops / sizeof tb_ops[0]; ++i)
    if (strcmp(t->op, tb_ops[i].name) == 0)
      k = (int)i;
  if (k < 0)
    return CQE_OP_NOT_MINE;
  enum tb_op op = tb_ops[k].op;
  uint32_t W = tb_width(t);
  if (W == 0) {
    cqe_fail("tmpl_bits: %s: width '%s' is not an integer type i<N>, N >= 1", t->op, t->w);
    return -1;
  }
  if (t->to[0] || t->pred[0] || t->rm || t->exc || t->strided) {
    cqe_fail("tmpl_bits: %s_%s: malformed name (to '%s', pred '%s', rm %u, exc %u, strided %u)", t->op,
             t->w, t->to, t->pred, t->rm, t->exc, t->strided);
    return -1;
  }
  if (nargs != tb_ops[k].arity) {
    cqe_fail("tmpl_bits: %s_%s takes %d data operands, got %d", t->op, t->w, tb_ops[k].arity, nargs);
    return -1;
  }
  if (op == TB_BSWAP && W % 16) {
    cqe_fail("tmpl_bits: bswap_%s: bswap is defined for W a multiple of 16 only", t->w);
    return -1;
  }
  uint32_t nw = tb_nwords(W);
  if (!out || !out->w || out->nw != nw || out->bits != W || out->kind != 'i') {
    cqe_fail("tmpl_bits: %s_%s: the core's result is not a preallocated i%u value", t->op, t->w, W);
    return -1;
  }
  for (int i = 0; i < nargs; ++i)
    if (args[i].nw && !args[i].w) {
      cqe_fail("tmpl_bits: %s_%s: operand %d has no storage", t->op, t->w, i);
      return -1;
    }

  uint64_t *a = tb_read(&args[0], W);
  uint64_t *b = nargs > 1 ? tb_read(&args[1], W) : NULL;
  uint64_t *c = nargs > 2 ? tb_read(&args[2], W) : NULL;
  uint64_t *r = tb_alloc(nw);
  uint64_t *u = tb_alloc(nw);

  switch (op) {
  case TB_AND:
    for (uint32_t i = 0; i < nw; ++i)
      r[i] = a[i] & b[i];
    break;
  case TB_OR:
    for (uint32_t i = 0; i < nw; ++i)
      r[i] = a[i] | b[i];
    break;
  case TB_XOR:
    for (uint32_t i = 0; i < nw; ++i)
      r[i] = a[i] ^ b[i];
    break;
  case TB_SHL:
    tb_shl(r, a, tb_mod(b, W), W);
    break;
  case TB_LSHR:
    tb_shr(r, a, tb_mod(b, W), W, 0);
    break;
  case TB_ASHR:
    tb_shr(r, a, tb_mod(b, W), W, tb_bit(a, W - 1));
    break;
  case TB_FSHL: { /* high W bits of (a:b) << s */
    uint32_t s = tb_mod(c, W);
    tb_shl(r, a, s, W);
    if (s) {
      tb_shr(u, b, W - s, W, 0);
      for (uint32_t i = 0; i < nw; ++i)
        r[i] |= u[i];
    }
    break;
  }
  case TB_FSHR: { /* low W bits of (a:b) >> s */
    uint32_t s = tb_mod(c, W);
    tb_shr(r, b, s, W, 0);
    if (s) {
      tb_shl(u, a, W - s, W);
      for (uint32_t i = 0; i < nw; ++i)
        r[i] |= u[i];
    }
    break;
  }
  case TB_BSWAP:
    for (uint32_t i = 0; i < W; ++i)
      tb_setbit(r, (W / 8 - 1 - i / 8) * 8 + i % 8, tb_bit(a, i));
    break;
  case TB_BITREVERSE:
    for (uint32_t i = 0; i < W; ++i)
      tb_setbit(r, W - 1 - i, tb_bit(a, i));
    break;
  case TB_CTLZ:
  case TB_CTTZ:
  case TB_CTPOP: {
    uint64_t n = 0;
    if (op == TB_CTPOP) {
      for (uint32_t i = 0; i < nw; ++i)
        n += (uint64_t)__builtin_popcountll(a[i]);
    } else if (op == TB_CTLZ) {
      while (n < W && !tb_bit(a, W - 1 - (uint32_t)n))
        ++n;
    } else {
      while (n < W && !tb_bit(a, (uint32_t)n))
        ++n;
    }
    r[0] = n; /* n <= W < 2^W for every W >= 1 */
    break;
  }
  }

  memcpy(out->w, r, nw * sizeof *r); /* every word; r is canonical (bits above W zero) */
  free(a);
  free(b);
  free(c);
  free(r);
  free(u);
  return 0;
}

__attribute__((constructor)) static void tb_register(void) {
  for (size_t i = 0; i < sizeof tb_ops / sizeof tb_ops[0]; ++i)
    cqe_register_op(tb_ops[i].name, tb_eval);
}
