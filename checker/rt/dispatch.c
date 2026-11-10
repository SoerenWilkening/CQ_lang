/* Checker dispatch (cq-w0-chk-core): the entry every generated stub calls, the core gates of
 * BACKEND_ABI §1 / CR §1.3, the template path, the family path, the op registry and the template
 * name parser.
 *
 * Stub entry (stubgen.py generates the callers; not part of cqe.h, private to chk-core):
 *   void cqe_dispatch(const char *sym, const char *sig, int32_t nargs, void **args, void *ret);
 *   sig  = "<ret>|<t0>,<t1>,..." with LLVM type spellings (void, i<N>, half, bfloat, float,
 *          double, x86_fp80, ptr); args[i] points at the i-th argument in memory (little-endian, store
 *          size); ret points at storage of the return type.
 *
 * Routing.
 *   cqrt_<core gate>  handled here: alloc, free, measure, ry[_qangle][_controlled], rz_i1,
 *                     rz_qangle[_controlled], not/and/or/xor_i1, copy[_controlled], xorc[_controlled]
 *                     (an in-place gate's _unc is the same call), push, pop.
 *   cq_template_*     parsed by cqe_parse_template; the handlers registered for tname.op are tried in
 *                     registration order. The core allocates the fresh result rail (forward) or XORs
 *                     the value into the out rail and checks the residue (_unc).
 *   cqrt_<other>      the family path: qram_alloc, qram_store, qram_load, qram_swap (rt_bus.c), tape_alloc,
 *                     tape_fmt, tape_effect, tape_write, abort (rt_tape.c). tname.op is that stem; tname.w the width token ("" if none); tname.shape "hl" for _hl and "l"
 *                     for _lit; tname.pred "ctl" for _controlled; tname.unc for _unc.
 *
 * Handler convention: cqe.h M1 (freeze bead cq-mgi), restated:
 *   return 0             out computed;
 *   return 1             CQE_OP_NOT_MINE: the name is outside this handler's family, no cqe_fail; the
 *                        next handler registered for the same op is tried; none accepting is a
 *                        violation (no_family);
 *   return -1            the handler called cqe_fail already.
 *   out                  on entry out->w is non-NULL with out->nw words of capacity, zeroed, and
 *                        out->bits/out->kind preset to the result width the name implies (templates)
 *                        or to the declared return type (family path; bits 0 for void). The handler
 *                        writes the value (bits above out->bits zero). The core owns out->w.
 *   template args        every forward argument in signature order (select condition, data operands,
 *                        the _rm/_rmq mode), each resolved: a handle to a
 *                        copy of its rail's value (bits = the rail's width), a literal to its value
 *                        with bits = its LLVM type's width, kind 'f' for half, bfloat (M2), float,
 *                        double and x86_fp80 (ptr: 64-bit 'i'). The _unc's leading out
 *                        handle is not passed. The handler computes f(args) whatever tname->unc says.
 *   family args          every ABI argument raw, in signature order: a handle as its i32 number, a
 *                        literal as its value, a ptr as a 64-bit 'i'. The family manages rails through
 *                        cqe_new_rail / cqe_rail / cqe_xor_into / cqe_set_known and returns a result
 *                        (a handle as i32) in out.
 *
 * Violations written here (event "violation", field "what"): bad_handle, use_after_free (core.c),
 * dirty_free (free of a rail that is not classical-valued and that no bus swap left at 0), free_forbidden (free of a measured, tape or
 * abort rail, BACKEND_ABI §1.2), unc_residue, unc_after_nondiagonal (an _unc after a non-diagonal
 * gate on its out rail or an operand since the out rail was computed, CR rule 5), width_mismatch,
 * target_aliases_operand, rotate_after_measure, pop_empty, malformed_call, bad_template,
 * unknown_symbol, no_family, result_width, fail (cqe_fail).
 *
 * cq_theta substitution (cq-6m2, cq-arch Z4; CR §6 item 1, "each cq_theta input replaced by a chosen
 * bit pattern"). When $CQE_THETA names a file, it is the C oracle's theta schedule for this sample
 * (run.py writes it): one line per cq_theta reach of the C program, in execution order,
 * `<angle> <W> <value>`: the reach's f64 angle bits (negated inside an odd number of cq_invert
 * regions), its register's width token and the chosen value it took, all hex. A Ry that fires (no
 * control, or a control whose basis value is 1) takes the earliest reach not yet taken with its width
 * and its angle (the literal, or the angle rail's value; any NaN equals any NaN): its target's basis
 * value becomes that reach's value before the gate is logged, so the ry event's "v" is the chosen
 * value, as the C side's "reg" is. With no reach of that exact angle, the untaken reach of that width
 * nearest in angle within THETA_NEAR_ULPS ulps is taken and {"ev":"theta_near",...} logged: the
 * circuit is wrong already (compare demands the exact angle), and the value keeps compare's verdict on
 * the angle rather than on a value. A firing Ry that matches no reach keeps its value and logs
 * {"ev":"theta_unmatched","h","w","angle"} (a diagnostic: the C program has no such cq_theta reach,
 * which compare reports on its own). Without $CQE_THETA nothing is substituted.
 */
#include <math.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cq_standin.h"
#include "cqe.h"
#include "rt_replay.h"


/* core.c internals */
uint32_t cqe__nwords(uint32_t bits);
uint32_t cqe__wtok_bits(const char *w, char *kind);
void cqe__val_init(cqe_val *v, uint32_t bits, char kind);
void cqe__val_free(cqe_val *v);
void cqe__val_mask(cqe_val *v);
void cqe__val_xor(cqe_val *dst, const cqe_val *src);
void cqe__val_copy_into(cqe_val *dst, const cqe_val *src);
int cqe__val_iszero(const cqe_val *v);
char *cqe__hexa(const cqe_val *v);
void cqe__init(void);
void cqe__logf(const char *fmt, ...);
void cqe__violation(const char *what, int32_t h, const char *fmt, ...);
uint64_t cqe__tick(void);
int32_t cqe__new(const char *w, const cqe_val *init, int known, int seed);
int cqe__check(int32_t h, const char *ctx);
int cqe__exists(int32_t h);
cqe_val *cqe__val(int32_t h);
const char *cqe__w(int32_t h);
int cqe__known(int32_t h);
void cqe__setknown(int32_t h, int k);
uint64_t cqe__created(int32_t h);
uint64_t cqe__last_nd(int32_t h);
int cqe__measured(int32_t h);
int cqe__role(int32_t h);
int cqe__busz(int32_t h);
void cqe__setrole(int32_t h, int role);
void cqe__setfenv(int32_t h, int bits); /* core.c (cq-tt2j) */
void cqe__mark_written(int32_t h);
void cqe__mark_nd(int32_t h);
void cqe__ry_note(int32_t h, uint64_t angle, const cqe_val *pre); /* core.c (cq-3o3v) */
int cqe__ry_unprep(int32_t h, uint64_t angle);
void cqe__ry_forget(int32_t h);
void cqe__mark_measured(int32_t h);
void cqe__add_dep(int32_t h, int32_t src);
void cqe__carry(int32_t into, const int32_t *srcs, int n); /* core.c (cq-qhow) */
int cqe__r6_before(int32_t t, int32_t y);                  /* core.c (cq-o9mx) */
void cqe__r6_cleaned(int32_t t, int32_t y);
void cqe__r6_unc(int32_t t, const int32_t *ops, int n);
int cqe__free_note(int32_t h, int known); /* core.c (cq-8m6v) */
void cqe__free(int32_t h);
char *cqe__hex(const cqe_val *v, char *buf);
int cqe__trace_all(void); /* core.c (cq-9hzgh): an event outside the compact set is written */
/* The same once the core is initialized (every gate body below runs after cqe__init), without the call (r7-fuse). */
extern int cqe__compact, cqe__shot_muted;
static inline int trace_all_(void) { return !cqe__compact && !cqe__shot_muted; }
/* core.c's fused gates (r7-fuse): 0 (alloc: handle 0) when the gate's general body must run; nothing is changed then. */
uint16_t cqe__wi_of(const char *w);
int cqe__f_logic(int is_and, int n, const uint64_t *a);
int cqe__f_copy(uint16_t wi, int ctl, const uint64_t *a);
int cqe__f_xorc(uint16_t wi, int ctl, const uint64_t *a, uint64_t lit);
int cqe__f_free(uint32_t h);
int32_t cqe__f_alloc(uint16_t wi, uint64_t lit);
int cqe__f_ops(int n, const uint32_t *hs, void **recs, uint64_t *v, uint32_t *bits, char *kind, int *known, int unc,
               uint32_t o, uint16_t owi, void **orec);
int32_t cqe__f_tnew(uint16_t wi, uint64_t val, int known, int nh, const uint32_t *hs, void *const *recs);
int cqe__f_tunc(uint32_t o, void *orec, uint64_t val, int r_ok, int nh, const uint32_t *hs, void *const *recs);

/* ---- values in place (cq-9hzgh) ---------------------------------------------------------------
 * A value of 64 bits or fewer the dispatcher holds for one call (an argument, a copy of a rail's value,
 * a result) lives in a word the caller provides; a wider one is allocated. val_drop frees only that. */
/* One-word forms of core.c's value operations, in line (cq-r6-dispatch): the same results, no call. A value of more
 * than one word goes to core.c. */
static inline uint32_t nwords_(uint32_t bits) { return bits ? (bits + 63) / 64 : 1; }
static inline void vmask_(cqe_val *v) {
  if (v->nw == 1) {
    if (v->bits == 0)
      v->w[0] = 0;
    else if (v->bits < 64)
      v->w[0] &= ((uint64_t)1 << v->bits) - 1;
  } else {
    cqe__val_mask(v);
  }
}
static inline void vxor_(cqe_val *dst, const cqe_val *src) {
  if (dst->nw == 1) {
    if (src->nw)
      dst->w[0] ^= src->w[0];
    vmask_(dst);
  } else {
    cqe__val_xor(dst, src);
  }
}
static inline int viszero_(const cqe_val *v) { return v->nw == 1 ? !v->w[0] : cqe__val_iszero(v); }
/* strcmp(a, b) == 0 for the short tokens of a call (a width token, a type spelling). */
static inline int streq_(const char *a, const char *b) {
  while (*a && *a == *b)
    ++a, ++b;
  return *a == *b;
}

static inline void val_in(cqe_val *v, uint32_t bits, char kind, uint64_t *inl) {
  v->bits = bits;
  v->kind = kind;
  v->nw = nwords_(bits);
  if (v->nw == 1) {
    *inl = 0;
    v->w = inl;
  } else {
    cqe__val_init(v, bits, kind);
  }
}

static inline void val_drop(cqe_val *v, const uint64_t *inl) {
  if (v->w == inl) {
    v->w = NULL;
    v->nw = 0;
  } else {
    cqe__val_free(v);
  }
}

/* ---- small string buffer ----------------------------------------------------------------- */

typedef struct {
  char *p;
  size_t len, cap;
} sbuf;

static void sb_add(sbuf *b, const char *s) {
  size_t n = strlen(s);
  if (b->len + n + 1 > b->cap) {
    b->cap = (b->len + n + 1) * 2;
    b->p = realloc(b->p, b->cap);
    if (!b->p)
      abort();
  }
  memcpy(b->p + b->len, s, n + 1);
  b->len += n;
}

static void sb_addf(sbuf *b, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
static void sb_addf(sbuf *b, const char *fmt, ...) {
  char tmp[512];
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(tmp, sizeof tmp, fmt, ap);
  va_end(ap);
  if (n < (int)sizeof tmp) {
    sb_add(b, tmp);
    return;
  }
  char *big = malloc((size_t)n + 1);
  if (!big)
    abort();
  va_start(ap, fmt);
  vsnprintf(big, (size_t)n + 1, fmt, ap);
  va_end(ap);
  sb_add(b, big);
  free(big);
}

static void sb_hex(sbuf *b, const cqe_val *v) {
  char *h = cqe__hexa(v);
  sb_add(b, h);
  free(h);
}

/* ---- registry ---------------------------------------------------------------------------- */

typedef struct {
  char op[24];
  cqe_op_fn fn;
} reg_t;
static reg_t *regs;
static size_t nregs, capregs;
static size_t reg_gen; /* cq-9hzgh: bumped at every registration; a site's cached handler list is of one generation */

void cqe_register_op(const char *op, cqe_op_fn fn) {
  cqe__init(); /* C1: every cqe_* entry initializes the core first (its atexit handler runs last) */
  if (!op || !fn)
    return;
  for (size_t i = 0; i < nregs; ++i)
    if (regs[i].fn == fn && strcmp(regs[i].op, op) == 0)
      return;
  if (nregs == capregs) {
    capregs = capregs ? 2 * capregs : 64;
    regs = realloc(regs, capregs * sizeof *regs);
    if (!regs)
      abort();
  }
  snprintf(regs[nregs].op, sizeof regs[nregs].op, "%s", op);
  regs[nregs].fn = fn;
  ++nregs;
  ++reg_gen;
}

/* The handlers registered for one op, in registration order (cq-9hzgh: a call site's, found once per
 * registry generation). */
#define HCACHE 8
typedef struct {
  size_t gen;
  int n;          /* -1: more than HCACHE, scan the registry */
  cqe_op_fn fn[HCACHE];
} hlist;

static void hlist_fill(hlist *l, const char *op) {
  l->gen = reg_gen + 1; /* never 0: a zeroed list is unfilled */
  l->n = 0;
  for (size_t i = 0; i < nregs; ++i) {
    if (strcmp(regs[i].op, op) != 0)
      continue;
    if (l->n == HCACHE) {
      l->n = -1;
      return;
    }
    l->fn[l->n++] = regs[i].fn;
  }
}

/* Try every handler of op in registration order. 0 computed, -1 failed (violation written). l: the op's
 * handler list, or NULL to scan the registry. */
static int run_handlers(const char *sym, const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out, hlist *l) {
  int seen = 0;
  if (l && l->gen != reg_gen + 1)
    hlist_fill(l, t->op);
  if (l && l->n < 0)
    l = NULL;
  size_t nh = l ? (size_t)l->n : nregs;
  for (size_t i = 0; i < nh; ++i) {
    cqe_op_fn fn = l ? l->fn[i] : regs[i].fn;
    if (!l && strcmp(regs[i].op, t->op) != 0)
      continue;
    seen = 1;
    if (out->nw == 1)
      out->w[0] = 0;
    else
      memset(out->w, 0, out->nw * sizeof *out->w);
    cqe_val pre = *out;
    int r = fn(t, args, nargs, out);
    if (out->w != pre.w || out->bits != pre.bits || out->kind != pre.kind || out->nw != pre.nw) {
      /* M1: the handler leaves out->w, bits, kind and nw as preset */
      cqe__violation("result_width", -1, "%s: handler changed the result buffer (bits %u->%u, kind %c->%c, nw %u->%u%s)",
                     sym, pre.bits, out->bits, pre.kind ? pre.kind : '?', out->kind ? out->kind : '?', pre.nw, out->nw,
                     out->w != pre.w ? ", storage replaced" : "");
      *out = pre;
      return -1;
    }
    if (r == CQE_OP_NOT_MINE)
      continue;
    if (r == 0) {
      vmask_(out);
      return 0;
    }
    return -1;
  }
  cqe__violation("no_family", -1, "%s: %s for op '%s'", sym, seen ? "every registered handler declined" : "no handler registered",
                 t->op);
  return -1;
}

/* ---- template name parser ---------------------------------------------------------------- */

static const char *const tmpl_ops[] = {
    "add", "sub", "mul", "udiv", "sdiv", "urem", "srem", "and", "or", "xor", "shl", "lshr", "ashr", "fadd", "fsub",
    "fmul", "fdiv", "frem", "fneg", "icmp", "fcmp", "fcmps", "select", "zext", "sext", "trunc", "fpext", "fptrunc",
    "sitofp", "uitofp", "fptosi", "fptoui", "bitcast", "fma", "fshl", "fshr", "abs", "ctlz", "cttz", "ctpop", "bswap", "bitreverse",
    "smax", "smin", "umax", "umin", "uadd_sat", "usub_sat", "sadd_sat", "ssub_sat", "uadd_overflow", "sadd_overflow", "usub_overflow",
    "ssub_overflow", "umul_overflow", "smul_overflow", "fabs", "copysign", "fmax", "fmin", "floor", "ceil", "rint",
    "round", "sqrt", "is_fpclass", NULL};
static const char *const icmp_preds[] = {"eq", "ne", "ugt", "uge", "ult", "ule", "sgt", "sge", "slt", "sle", NULL};
static const char *const fcmp_preds[] = {"false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq",
                                         "ugt",   "uge", "ult", "ule", "une", "uno", "true", NULL};

static int in_list(const char *s, const char *const *l) {
  for (; *l; ++l)
    if (strcmp(s, *l) == 0)
      return 1;
  return 0;
}

static int put(char *dst, size_t cap, const char *src, size_t n) {
  if (n + 1 > cap)
    return -1;
  memcpy(dst, src, n);
  dst[n] = 0;
  return 0;
}

int cqe_parse_template(const char *sym, cqe_tname *out) {
  cqe__init();
  if (!sym || !out)
    return -1;
  memset(out, 0, sizeof *out);
  if (strncmp(sym, "cq_template_", 12) == 0)
    sym += 12;
  /* op: the longest op name followed by '_' */
  size_t best = 0;
  for (const char *const *o = tmpl_ops; *o; ++o) {
    size_t n = strlen(*o);
    if (n > best && strncmp(sym, *o, n) == 0 && sym[n] == '_')
      best = n;
  }
  if (!best || put(out->op, sizeof out->op, sym, best))
    return -1;
  const char *p = sym + best + 1;
  /* tokens */
  char tok[16][32];
  int nt = 0;
  while (*p) {
    const char *e = strchr(p, '_');
    size_t n = e ? (size_t)(e - p) : strlen(p);
    if (n == 0 || n >= sizeof tok[0] || nt == 16)
      return -1;
    memcpy(tok[nt], p, n);
    tok[nt][n] = 0;
    ++nt;
    p += n;
    if (*p == '_') {
      ++p;
      if (!*p)
        return -1;
    }
  }
  int i = 0;
  int is_icmp = strcmp(out->op, "icmp") == 0, is_fcmp = !strcmp(out->op, "fcmp") || !strcmp(out->op, "fcmps");
  if (is_icmp || is_fcmp) {
    if (i >= nt || !in_list(tok[i], is_icmp ? icmp_preds : fcmp_preds) || put(out->pred, sizeof out->pred, tok[i], strlen(tok[i])))
      return -1;
    ++i;
  }
  if (i >= nt || !cqe__wtok_bits(tok[i], NULL) || put(out->w, sizeof out->w, tok[i], strlen(tok[i])))
    return -1;
  ++i;
  if (i < nt && strcmp(tok[i], "to") == 0) {
    ++i;
    if (i >= nt || !cqe__wtok_bits(tok[i], NULL) || put(out->to, sizeof out->to, tok[i], strlen(tok[i])))
      return -1;
    ++i;
  }
  if (i < nt && strspn(tok[i], "hlq") == strlen(tok[i]) && strcmp(tok[i], "") != 0) {
    if (put(out->shape, sizeof out->shape, tok[i], strlen(tok[i])))
      return -1;
    ++i;
  }
  if (i < nt && (strcmp(tok[i], "rm") == 0 || strcmp(tok[i], "rmq") == 0)) {
    out->rm = tok[i][2] ? 2 : 1;
    ++i;
  }
  if (i < nt && strcmp(tok[i], "exc") == 0) {
    out->exc = 1;
    ++i;
  }
  if (i < nt && strcmp(tok[i], "unc") == 0) {
    out->unc = 1;
    ++i;
  }
  return i == nt ? 0 : -1;
}

/* Result width token of a template (BACKEND_ABI §2.1): i1 for compares, *_overflow and is_fpclass;
 * the _to_ width for casts; i32 for _exc; else W. */
static const char *result_w(const cqe_tname *t) {
  size_t n = strlen(t->op);
  if (t->exc)
    return "i32";
  if (!strcmp(t->op, "icmp") || !strcmp(t->op, "fcmp") || !strcmp(t->op, "fcmps") || !strcmp(t->op, "is_fpclass") ||
      (n > 9 && !strcmp(t->op + n - 9, "_overflow")))
    return "i1";
  if (t->to[0])
    return t->to;
  return t->w;
}

/* Handle/literal layout of the nf forward arguments: mask[i] = 'h' or 'l'. 0 ok, -1 inconsistent. */
int cqe__template_layout(const cqe_tname *t, int nf, char *mask) {
  if (nf < 0 || nf > 64)
    return -1;
  int k = 0, sel = !strcmp(t->op, "select");
  int nd = nf - sel - (t->rm ? 1 : 0);
  if (nd < 1)
    return -1;
  if (sel)
    mask[k++] = 'h';
  if (t->shape[0]) {
    if ((int)strlen(t->shape) != nd)
      return -1;
    for (int i = 0; i < nd; ++i)
      mask[k++] = t->shape[i] == 'l' ? 'l' : 'h';
  } else {
    for (int i = 0; i < nd; ++i)
      mask[k++] = 'h';
  }
  if (t->rm)
    mask[k++] = t->rm == 2 ? 'h' : 'l';
  mask[k] = 0;
  return 0;
}

/* ---- arguments --------------------------------------------------------------------------- */

typedef struct {
  char ty[16];
  uint32_t bits, bytes;
  char kind; /* 'i', 'f', 'p', 'v' */
  uint8_t is_i32, is_double; /* ty is "i32", "double" (cq-r6-dispatch: read per call in place of a strcmp) */
  uint64_t mask;             /* the low bits of a value of at most 64 bits */
} lty;

static int parse_lty(const char *s, size_t n, lty *t) {
  memset(t, 0, sizeof *t);
  if (n == 0 || n >= sizeof t->ty)
    return -1;
  memcpy(t->ty, s, n);
  t->ty[n] = 0;
  if (!strcmp(t->ty, "void")) {
    t->kind = 'v';
    return 0;
  }
  if (!strcmp(t->ty, "ptr")) {
    t->kind = 'p';
    t->bits = 64;
  } else if (!strcmp(t->ty, "half") || !strcmp(t->ty, "bfloat")) { /* M2: bfloat is kind 'f' */
    t->kind = 'f';
    t->bits = 16;
  } else if (!strcmp(t->ty, "float")) {
    t->kind = 'f';
    t->bits = 32;
  } else if (!strcmp(t->ty, "double")) {
    t->kind = 'f';
    t->bits = 64;
  } else if (!strcmp(t->ty, "x86_fp80")) {
    t->kind = 'f';
    t->bits = 80;
  } else if (t->ty[0] == 'i' && cqe__wtok_bits(t->ty, NULL)) {
    t->kind = 'i';
    t->bits = cqe__wtok_bits(t->ty, NULL);
  } else {
    return -1;
  }
  t->bytes = (t->bits + 7) / 8;
  t->is_i32 = !strcmp(t->ty, "i32");
  t->is_double = !strcmp(t->ty, "double");
  t->mask = t->bits >= 64 ? ~(uint64_t)0 : ((uint64_t)1 << t->bits) - 1;
  return 0;
}

static void load_val(cqe_val *v, const lty *t, const void *mem) {
  cqe__val_init(v, t->bits, t->kind == 'f' ? 'f' : 'i');
  memcpy(v->w, mem, t->bytes);
  cqe__val_mask(v);
}

/* load_val into an in-place word when it fits (val_in). */
static inline void load_val_in(cqe_val *v, const lty *t, const void *mem, uint64_t *inl) {
  val_in(v, t->bits, t->kind == 'f' ? 'f' : 'i', inl);
  memcpy(v->w, mem, t->bytes);
  vmask_(v);
}

static void store_val(void *mem, const lty *t, const cqe_val *v) {
  if (t->kind == 'v' || !mem)
    return;
  if (t->bytes <= 8) { /* cq-9hzgh: what the general case below does for one word */
    uint64_t x = v->nw ? v->w[0] : 0;
    if (t->bits < 64)
      x &= (1ULL << t->bits) - 1;
    memcpy(mem, &x, t->bytes);
    return;
  }
  uint8_t tmp[16 * 64];
  size_t nb = t->bytes;
  memset(tmp, 0, sizeof tmp);
  if (nb > sizeof tmp)
    nb = sizeof tmp;
  size_t have = (size_t)v->nw * 8;
  memcpy(tmp, v->w, have < nb ? have : nb);
  if (t->bits % 8)
    tmp[nb - 1] &= (uint8_t)((1u << (t->bits % 8)) - 1);
  memcpy(mem, tmp, nb);
}

/* store_val of a value of one word (a handle, a popped word). */
static void store_word(void *mem, const lty *t, uint64_t x) {
  cqe_val v = {64, 'i', 1, &x};
  store_val(mem, t, &v);
}

static int32_t as_i32(const cqe_val *v) { return (int32_t)(uint32_t)v->w[0]; }

static double as_f64(const cqe_val *v) {
  double d;
  memcpy(&d, v->w, 8);
  return d;
}

/* ---- known-basis rule for XOR-into writes ------------------------------------------------ */

/* After an XOR-into write on d from the given sources (controls included): if d is now 0, d is
 * known iff no rail among d and the sources took a non-diagonal gate after the latest creation of
 * d and the sources (returns 0 when that test fails, 1 otherwise); if d is nonzero it is known iff
 * d and every source were known. */
static inline int zero_rule_v(int32_t d, const cqe_val *dv, const int32_t *src, int ns) {
  if (viszero_(dv)) {
    uint64_t ref = cqe__created(d);
    for (int i = 0; i < ns; ++i)
      if (cqe__created(src[i]) > ref)
        ref = cqe__created(src[i]);
    int ok = cqe__last_nd(d) <= ref;
    for (int i = 0; i < ns; ++i)
      if (cqe__last_nd(src[i]) > ref)
        ok = 0;
    cqe__setknown(d, ok);
    return ok;
  }
  int k = cqe__known(d);
  for (int i = 0; i < ns; ++i)
    k = k && cqe__known(src[i]);
  cqe__setknown(d, k);
  return 1;
}
static inline int zero_rule_(int32_t d, const int32_t *src, int ns) { return zero_rule_v(d, cqe__val(d), src, ns); }
int cqe__zero_rule(int32_t d, const int32_t *src, int ns) { return zero_rule_(d, src, ns); }

/* ---- core gates -------------------------------------------------------------------------- */

/* cq-4593 (BACKEND_ABI 1.13): set while a cq_invert region's replay runs a declared clone's twin as the rail's
 * compute (the reversed list takes a compute/uncompute pair the other way round): no residue to check. */
static int iv_quiet_unc;

static int32_t *stack_;
static size_t nstack, capstack;

/* cq-kcn5i (rt_replay.c): a replay window may push and pop its own words only; popping one pushed before it began, or
 * ending with another depth, makes it dirty. */
static size_t rp_floor;
static int rp_floor_on;
void cqe__rp_stack_mark(int on) {
  rp_floor_on = on;
  rp_floor = nstack;
}
int cqe__rp_stack_same(void) { return nstack == rp_floor; }

typedef struct {
  const char *sym;
  int nargs;
  const lty *ty;
  cqe_val *raw;
  const lty *rty;
  void *ret;
} call_t;

static int want_args(const call_t *c, int n, const char *types) {
  /* types: one char per arg: 'h' i32 handle, 'd' double, 'L' any literal */
  if (c->nargs != n) {
    cqe__violation("malformed_call", -1, "%s: %d arguments, expected %d", c->sym, c->nargs, n);
    return 0;
  }
  for (int i = 0; i < n; ++i) {
    if (types[i] == 'h' && !c->ty[i].is_i32) {
      cqe__violation("malformed_call", -1, "%s: argument %d is %s, expected an i32 handle", c->sym, i, c->ty[i].ty);
      return 0;
    }
    if (types[i] == 'd' && !c->ty[i].is_double) {
      cqe__violation("malformed_call", -1, "%s: argument %d is %s, expected double", c->sym, i, c->ty[i].ty);
      return 0;
    }
  }
  return 1;
}

/* Check a handle operand is live and (if w) of width w. 1 usable. */
static inline int operand_(const char *sym, int32_t h, const char *w) {
  int r = cqe__check(h, sym);
  if (r < 0)
    return 0;
  if (w && !streq_(cqe__w(h), w)) {
    cqe__violation("width_mismatch", h, "%s: rail %d is %s, expected %s", sym, (int)h, cqe__w(h), w);
    return 0;
  }
  return 1;
}
static int operand(const call_t *c, int32_t h, const char *w) { return operand_(c->sym, h, w); }

/* A width token with its bits and kind (cq-r6-dispatch). kind 0: the token alone tells (f16 and bf16 share bits and
 * kind; core.c keeps 7 characters of a token). */
typedef struct {
  const char *w;
  uint32_t bits;
  char kind;
} wspec;
static const wspec W_I1 = {"i1", 1, 'i'};
static inline wspec wspec_of(const char *w) {
  wspec s = {w, 0, 0};
  char kind = 0;
  uint32_t bits = cqe__wtok_bits(w, &kind);
  if (bits && strlen(w) < 7 && !(kind == 'f' && bits == 16))
    s.bits = bits, s.kind = kind;
  return s;
}

/* operand_ for a rail whose value the gate reads next: *v is the rail's value (cqe__val), read for the width as
 * well, so a live rail of the right width costs one look at its record less. The same verdicts and violations: a
 * live rail has width token W iff its value has W's bits and kind (W.kind set); a freed rail, a mismatch and a W
 * that only its token tells are decided by the token, as operand_ decides them. */
static inline int operand_v(const char *sym, int32_t h, const wspec *W, cqe_val **v) {
  int r = cqe__check(h, sym);
  if (r < 0)
    return 0;
  if (r == 0 && W->kind) {
    cqe_val *x = cqe__val(h);
    if (x->bits == W->bits && x->kind == W->kind) {
      *v = x;
      return 1;
    }
  }
  if (!streq_(cqe__w(h), W->w)) {
    cqe__violation("width_mismatch", h, "%s: rail %d is %s, expected %s", sym, (int)h, cqe__w(h), W->w);
    return 0;
  }
  *v = cqe__val(h);
  return 1;
}

static inline int distinct_(const char *sym, int32_t target, const int32_t *others, int n) {
  for (int i = 0; i < n; ++i)
    if (others[i] == target) {
      cqe__violation("target_aliases_operand", target, "%s: in-place target %d is also operand", sym, (int)target);
      return 0;
    }
  return 1;
}
static int distinct(const call_t *c, int32_t target, const int32_t *others, int n) { return distinct_(c->sym, target, others, n); }

static void log_gate_full(const char *sym, int32_t h, const int32_t *srcs, int ns) {
  sbuf b = {0};
  sb_addf(&b, "{\"ev\":\"gate\",\"sym\":\"%s\",\"h\":%d,\"v\":\"", sym, (int)h);
  sb_hex(&b, cqe__val(h));
  sb_addf(&b, "\",\"known\":%s,\"args\":[", cqe__known(h) ? "true" : "false");
  for (int i = 0; i < ns; ++i)
    sb_addf(&b, "%s%d", i ? "," : "", (int)srcs[i]);
  sb_add(&b, "]}");
  cqe_log(b.p);
  free(b.p);
}
static inline void log_gate_(const char *sym, int32_t h, const int32_t *srcs, int ns) {
  if (trace_all_()) /* cq-9hzgh: not in a compact trace */
    log_gate_full(sym, h, srcs, ns);
}

static void log_rot(const char *ev, const call_t *c, int32_t h, int32_t ctl, const char *angle_fields,
                    const char *pre) {
  sbuf b = {0};
  sb_addf(&b, "{\"ev\":\"%s\",\"h\":%lld,%s,\"ctl\":[", ev, cqe__hname(h), angle_fields);
  if (ctl > 0)
    sb_addf(&b, "%lld", cqe__hname(ctl));
  sb_add(&b, "],\"ctlv\":[");
  if (ctl > 0)
    sb_addf(&b, "%d", (int)(cqe__val(ctl)->w[0] & 1));
  sb_addf(&b, "],\"w\":\"%s\",\"v\":\"", cqe__w(h));
  sb_hex(&b, cqe__val(h));
  if (pre) {
    sb_add(&b, "\",\"pre\":\"");
    sb_add(&b, pre);
  }
  sb_add(&b, "\"}");
  cqe_log(b.p);
  free(b.p);
  (void)c;
}

/* Parse "<W>" from the start of s; returns pointer after it, or NULL. */
static const char *take_w(const char *s, char *w, size_t cap) {
  const char *e = strchr(s, '_');
  size_t n = e ? (size_t)(e - s) : strlen(s);
  if (n == 0 || n >= cap)
    return NULL;
  memcpy(w, s, n);
  w[n] = 0;
  if (!cqe__wtok_bits(w, NULL))
    return NULL;
  return s + n;
}

/* Suffix flags after the width: any of _controlled, _qangle, _unc in the given allowed set, order
 * qangle, controlled, unc. Returns 0 ok. */
static int suffixes(const char *s, int allow_q, int allow_c, int allow_u, int *q, int *ctl, int *unc) {
  *q = *ctl = *unc = 0;
  if (allow_q && !strncmp(s, "_qangle", 7)) {
    *q = 1;
    s += 7;
  }
  if (allow_c && !strncmp(s, "_controlled", 11)) {
    *ctl = 1;
    s += 11;
  }
  if (allow_u && !strncmp(s, "_unc", 4)) {
    *unc = 1;
    s += 4;
  }
  return *s ? -1 : 0;
}

/* The gates below (alloc, free, not/and/or/xor_i1, copy, xorc, push, pop) are written over their typed operands
 * (cq-r6-dispatch): the generic entry checks the stub's signature and calls them, a call site whose signature is the
 * gate's own calls them straight from its words (the fast_* functions further down). One body, both ways. */
static inline int32_t g_alloc(const char *w, const cqe_val *lit) {
  int32_t h = cqe__new(w, lit, 1, 1);
  if (trace_all_()) { /* cq-9hzgh: not in a compact trace */
    char *hx = cqe__hexa(cqe__val(h));
    cqe__logf("{\"ev\":\"alloc\",\"h\":%d,\"w\":\"%s\",\"v\":\"%s\",\"known\":true}", (int)h, w, hx);
    free(hx);
  }
  return h;
}

static void gate_alloc(call_t *c, const char *w) {
  if (c->nargs != 1 || !c->rty->is_i32) {
    cqe__violation("malformed_call", -1, "%s: expected (lit) -> i32", c->sym);
    return;
  }
  store_word(c->ret, c->rty, (uint32_t)g_alloc(w, &c->raw[0]));
}

static inline void g_free(const char *sym, int32_t h) {
  if (cqe__check(h, sym) != 0)
    return;
  /* ABI §1.2: a classical-valued rail in any basis value; ABI §1.10 Undo 2: the rail the cells' 0 went to */
  int known = cqe__known(h) || cqe__busz(h);
  if (cqe__free_note(h, known)) {
    char hb[3 + 16 * 2 + 1], *hx = cqe__val(h)->nw <= 2 ? cqe__hex(cqe__val(h), hb) : cqe__hexa(cqe__val(h));
    cqe__logf("{\"ev\":\"free\",\"h\":%lld,\"v\":\"%s\",\"known\":%s,\"w\":\"%s\"}", cqe__hname(h), hx, known ? "true" : "false",
            cqe__w(h));
    if (hx != hb)
      free(hx);
  }
  int meas = cqe__measured(h), role = meas ? 0 : cqe__role(h);
  if (meas || role == 1 || role == 2)
    cqe__violation("free_forbidden", h, "%s: rail %d is a %s rail", sym, (int)h, meas ? "measured" : role == 1 ? "abort" : "tape");
  if (!known)
    cqe__violation("dirty_free", h, "%s: rail %d is not classical-valued and does not read 0 by a bus swap", sym, (int)h);
  cqe__free(h);
}

static void gate_free(call_t *c) {
  if (!want_args(c, 1, "h"))
    return;
  g_free(c->sym, as_i32(&c->raw[0]));
}

static void gate_measure(call_t *c, const char *w) {
  if (!want_args(c, 1, "h"))
    return;
  int32_t h = as_i32(&c->raw[0]);
  if (!operand(c, h, w))
    return;
  int reread = cqe__measured(h);   /* CR rule 2, ABI 1.3 (cq-ihlt): a classical re-read, no measure event */
  cqe__mark_measured(h);
  if (!reread) {
    char hb[3 + 16 * 2 + 1], *hx = cqe__val(h)->nw <= 2 ? cqe__hex(cqe__val(h), hb) : cqe__hexa(cqe__val(h));
    cqe__logf("{\"ev\":\"measure\",\"h\":%lld,\"v\":\"%s\",\"w\":\"%s\"}", cqe__hname(h), hx, w);
    if (hx != hb)
      free(hx);
  }
  store_val(c->ret, c->rty, cqe__val(h));
}

/* ---- cq_theta substitution (cq-6m2, Z4; see the header) -------------------------------------- */

typedef struct { uint64_t angle, v[2]; char w[8]; int taken; } theta_reach;
static theta_reach *theta_sched;
static int theta_n, theta_loaded;
static const char *theta_text; /* cqe__theta_use: the schedule's text in memory, in place of $CQE_THETA */
static size_t theta_textn;
static int theta_text_set;

/* A batch runner's shot (core.c, cq-e2i9): forget any schedule and take this sample's from memory
 * (text NULL: no schedule, the sample substitutes nothing). Called in the forked child before the
 * sample's call. */
void cqe__theta_use(const char *text, size_t n) {
  free(theta_sched);
  theta_sched = NULL;
  theta_n = theta_loaded = 0;
  theta_text = text;
  theta_textn = n;
  theta_text_set = 1;
}

static void theta_load(void) {
  theta_loaded = 1;
  FILE *f;
  const char *path = "(memory)";
  if (theta_text_set) {
    if (!theta_text || !theta_textn)
      return;
    f = fmemopen((void *)theta_text, theta_textn, "r");
  } else {
    path = getenv("CQE_THETA");
    if (!path || !*path)
      return;
    f = fopen(path, "r");
  }
  if (!f) {
    cqe__violation("fail", -1, "CQE_THETA: cannot open %s", path);
    return;
  }
  char line[256];
  int cap = 0;
  while (fgets(line, sizeof line, f)) {
    char a[40], w[16], v[48];
    if (sscanf(line, "%39s %15s %47s", a, w, v) != 3) {
      if (strspn(line, " \t\r\n") == strlen(line))
        continue;
      cqe__violation("fail", -1, "CQE_THETA: malformed line '%s'", line);
      break;
    }
    if (theta_n == cap) {
      cap = cap ? 2 * cap : 64;
      theta_sched = realloc(theta_sched, (size_t)cap * sizeof *theta_sched);
      if (!theta_sched)
        abort();
    }
    theta_reach *r = &theta_sched[theta_n++];
    memset(r, 0, sizeof *r);
    r->angle = strtoull(a, 0, 16);
    snprintf(r->w, sizeof r->w, "%s", w);
    /* up to 128 bits: the low 64 from the last 16 digits */
    const char *d = v + ((v[0] == '0' && (v[1] == 'x' || v[1] == 'X')) ? 2 : 0);
    size_t n = strlen(d);
    if (n > 16) {
      char hi[24];
      snprintf(hi, sizeof hi, "%.*s", (int)(n - 16), d);
      r->v[1] = strtoull(hi, 0, 16);
      r->v[0] = strtoull(d + n - 16, 0, 16);
    } else {
      r->v[0] = strtoull(d, 0, 16);
    }
  }
  fclose(f);
}

static int f64_nan(uint64_t b) { return ((b >> 52) & 0x7FF) == 0x7FF && (b & ((1ULL << 52) - 1)); }

/* f64 bits as an integer ordered like the doubles (ulp distance = difference) */
static int64_t f64_ordered(uint64_t b) { return (b >> 63) ? -(int64_t)(b & ~(1ULL << 63)) : (int64_t)b; }

#define THETA_NEAR_ULPS (1ULL << 32) /* an angle within this many ulps of a reach's still takes it */

/* A firing Ry on rail h with angle bits `angle`: take the schedule's reach (header). 1 when it took
 * one, 0 when there is no schedule, -1 when it matched no reach. */
static int theta_substitute(int32_t h, uint64_t angle) {
  if (!theta_loaded)
    theta_load();
  if (!theta_sched)
    return 0;
  const char *w = cqe__w(h);
  theta_reach *r = NULL, *near = NULL;
  uint64_t best = THETA_NEAR_ULPS + 1;
  for (int i = 0; i < theta_n && !r; ++i) {
    theta_reach *c = &theta_sched[i];
    if (c->taken || strcmp(c->w, w) != 0)
      continue;
    if (c->angle == angle || (f64_nan(c->angle) && f64_nan(angle))) {
      r = c;
      break;
    }
    if (!f64_nan(c->angle) && !f64_nan(angle)) {
      int64_t a = f64_ordered(c->angle), b = f64_ordered(angle);
      uint64_t d = a > b ? (uint64_t)a - (uint64_t)b : (uint64_t)b - (uint64_t)a;
      if (d < best)
        best = d, near = c;
    }
  }
  if (!r && near) {
    /* no reach has this exact angle: the circuit is already wrong (compare demands the exact angle);
     * an angle a few ulps off still takes its reach, so compare reports the angle, not a value */
    r = near;
    cqe__logf("{\"ev\":\"theta_near\",\"h\":%d,\"w\":\"%s\",\"angle\":\"0x%llx\",\"reach\":\"0x%llx\"}", (int)h, w,
              (unsigned long long)angle, (unsigned long long)r->angle);
  }
  if (r) {
    r->taken = 1;
    cqe_val *x = cqe__val(h);
    for (uint32_t k = 0; k < x->nw; ++k)
      x->w[k] = k < 2 ? r->v[k] : 0;
    if (x->bits % 64)
      x->w[x->nw - 1] &= (1ULL << (x->bits % 64)) - 1;
    return 1;
  }
  cqe__logf("{\"ev\":\"theta_unmatched\",\"h\":%d,\"w\":\"%s\",\"angle\":\"0x%llx\"}", (int)h, w,
            (unsigned long long)angle);
  return -1;
}

/* A firing Ry (cq-3o3v): its target's value before the gate is the record's "pre" (compare checks it
 * against the C register's value at the cq_theta site the gate takes, before the C side substitutes
 * it). The substitution then sets the chosen value. A firing Ry that took a reach is noted on its
 * rail; one that matched no reach and is the noted Ry's adjoint on an untouched rail (CR rule 10's
 * un-prep) puts the noted pre-value back after it is logged (its record's "v" stays the value it
 * acted on), as Ry(-θ)·Ry(θ) = I. */
static char *ry_fire(int32_t h, uint64_t angle, int *undo) {
  cqe_val *x = cqe__val(h);
  cqe_val pre = *x;
  pre.w = malloc((x->nw ? x->nw : 1) * sizeof *pre.w);
  if (!pre.w)
    abort();
  memcpy(pre.w, x->w, x->nw * sizeof *pre.w);
  char *hx = cqe__hexa(&pre);
  int got = theta_substitute(h, angle);
  *undo = 0;
  if (got > 0)
    cqe__ry_note(h, angle, &pre);
  else if (got < 0)
    *undo = 1;
  else
    cqe__ry_forget(h);
  free(pre.w);
  return hx;
}

static void gate_ry(call_t *c, const char *w, int q, int ctl) {
  int n = (ctl ? 1 : 0) + 2;
  if (!want_args(c, n, ctl ? (q ? "hhh" : "hhd") : (q ? "hh" : "hd")))
    return;
  int32_t cf = ctl ? as_i32(&c->raw[0]) : 0, h = as_i32(&c->raw[ctl ? 1 : 0]);
  if (ctl && !operand(c, cf, "i1"))
    return;
  if (!operand(c, h, w))
    return;
  if (ctl && !distinct(c, h, &cf, 1))
    return;
  if (cqe__measured(h))
    cqe__violation("rotate_after_measure", h, "%s: rail %d was measured", c->sym, (int)h);
  char fields[256];
  int undo = 0;
  uint64_t ang;
  char *pre = NULL; /* the target's value before a firing gate (cq-3o3v) */
  if (q) {
    int32_t a = as_i32(&c->raw[n - 1]);
    if (!operand(c, a, "f64"))
      return;
    if (!distinct(c, h, &a, 1))
      return;
    double av = as_f64(cqe__val(a));
    memcpy(&ang, &av, 8);
    if (!ctl || (cqe__val(cf)->w[0] & 1))
      pre = ry_fire(h, ang, &undo);
    char *hx = cqe__hexa(cqe__val(a));
    snprintf(fields, sizeof fields, "\"a\":%lld,\"aval\":\"%s\"", cqe__hname(a), hx);
    free(hx);
    log_rot("ry_qangle", c, h, cf, fields, pre);
    cqe__add_dep(h, a);
  } else {
    ang = c->raw[n - 1].w[0];
    if (!ctl || (cqe__val(cf)->w[0] & 1))
      pre = ry_fire(h, ang, &undo);
    snprintf(fields, sizeof fields, "\"theta\":\"0x%llx\"", (unsigned long long)c->raw[n - 1].w[0]);
    log_rot("ry", c, h, cf, fields, pre);
  }
  free(pre);
  if (undo && cqe__ry_unprep(h, ang))
    cqe__logf("{\"ev\":\"ry_unprep\",\"h\":%d}", (int)h);
  if (ctl)
    cqe__add_dep(h, cf);
  cqe__mark_nd(h);
  if (!(ctl && cqe__known(cf) && (cqe__val(cf)->w[0] & 1) == 0))
    cqe__setknown(h, 0);
}

static void gate_rz_i1(call_t *c) {
  if (!want_args(c, 2, "hd"))
    return;
  int32_t f = as_i32(&c->raw[0]);
  if (!operand(c, f, "i1"))
    return;
  cqe__logf("{\"ev\":\"phase\",\"f\":%lld,\"fv\":%d,\"theta\":\"0x%llx\"}", cqe__hname(f), (int)(cqe__val(f)->w[0] & 1),
            (unsigned long long)c->raw[1].w[0]);
}

static void gate_rz_qangle(call_t *c, int ctl) {
  if (!want_args(c, ctl ? 2 : 1, ctl ? "hh" : "h"))
    return;
  int32_t cf = ctl ? as_i32(&c->raw[0]) : 0, a = as_i32(&c->raw[ctl ? 1 : 0]);
  if (ctl && !operand(c, cf, "i1"))
    return;
  if (!operand(c, a, "f64"))
    return;
  sbuf b = {0};
  sb_addf(&b, "{\"ev\":\"phase_qangle\",\"a\":%lld,\"aval\":\"", cqe__hname(a));
  sb_hex(&b, cqe__val(a));
  sb_add(&b, "\",\"ctl\":[");
  if (ctl)
    sb_addf(&b, "%lld", cqe__hname(cf));
  sb_add(&b, "],\"ctlv\":[");
  if (ctl)
    sb_addf(&b, "%d", (int)(cqe__val(cf)->w[0] & 1));
  sb_add(&b, "]}");
  cqe_log(b.p);
  free(b.p);
}

/* not/and/or/xor_i1 on the n handles hs (the last one the target). lop: LOP_*. */
enum { LOP_NOT, LOP_AND, LOP_OR, LOP_XOR };
static inline void g_logic(const char *sym, int lop, int n, const int32_t *hs) {
  cqe_val *v[3];
  for (int i = 0; i < n; ++i)
    if (!operand_v(sym, hs[i], &W_I1, &v[i]))
      return;
  int32_t t = hs[n - 1];
  if (!distinct_(sym, t, hs, n - 1))
    return;
  uint64_t a = n > 1 ? v[0]->w[0] & 1 : 0, b = n > 2 ? v[1]->w[0] & 1 : 0, d;
  if (n == 1)
    d = 1;
  else if (n == 2)
    d = a;
  else
    d = lop == LOP_AND ? (a & b) : (a | b);
  v[n - 1]->w[0] ^= d;
  cqe__carry(t, hs, n - 1);
  cqe__mark_written(t);
  for (int i = 0; i < n - 1; ++i)
    cqe__add_dep(t, hs[i]);
  zero_rule_v(t, v[n - 1], hs, n - 1);   /* not_i1 too: a flag an X returns to 0 is known again (cq-aypc) */
  log_gate_(sym, t, hs, n - 1);
}
static inline int logic_n(int lop) { return lop == LOP_NOT ? 1 : lop == LOP_XOR ? 2 : 3; }

static void gate_logic(call_t *c, int lop) {
  int n = logic_n(lop);
  if (!want_args(c, n, n == 1 ? "h" : n == 2 ? "hh" : "hhh"))
    return;
  int32_t hs[3];
  for (int i = 0; i < n; ++i)
    hs[i] = as_i32(&c->raw[i]);
  g_logic(c->sym, lop, n, hs);
}

/* copy_<W>(a, d) / xorc_<W>(a, lit), under the control cf when ctl. */
static inline void g_copy_xorc(const char *sym, const wspec *W, int is_copy, int ctl, int32_t cf, int32_t a, int32_t d,
                               const cqe_val *lit) {
  cqe_val *cv = NULL, *av, *tv;
  if (ctl && !operand_v(sym, cf, &W_I1, &cv))
    return;
  int32_t target, srcs[2];
  int ns = 0;
  const cqe_val *delta;
  if (is_copy) {
    if (!operand_v(sym, a, W, &av) || !operand_v(sym, d, W, &tv))
      return;
    target = d;
    srcs[ns++] = a;
    delta = av;
  } else {
    if (!operand_v(sym, a, W, &tv))
      return;
    target = a;
    delta = lit;
  }
  if (ctl)
    srcs[ns++] = cf;
  if (!distinct_(sym, target, srcs, ns))
    return;
  int fire = !ctl || (cv->w[0] & 1);
  if (ctl && cqe__known(cf) && !fire) {
    log_gate_(sym, target, srcs, ns); /* known control 0: nothing happens on any branch */
    return;
  }
  int r6 = is_copy && !ctl && cqe__r6_before(a, target); /* before the write stamps target */
  if (fire)
    vxor_(tv, delta);
  if (is_copy)
    cqe__carry(target, srcs, 1); /* the data source, not the control */
  cqe__mark_written(target);
  for (int i = 0; i < ns; ++i)
    cqe__add_dep(target, srcs[i]);
  if (is_copy || ctl)
    zero_rule_v(target, tv, srcs, ns);
  if (r6)
    cqe__r6_cleaned(a, target);
  log_gate_(sym, target, srcs, ns);
}

/* copy_<W>(s, d), xorc_<W>(h, lit), with optional control first. */
static void gate_copy_xorc(call_t *c, const char *w, int is_copy, int ctl) {
  int n = (ctl ? 1 : 0) + 2;
  char types[4] = {0};
  int k = 0;
  if (ctl)
    types[k++] = 'h';
  types[k++] = 'h';
  types[k++] = is_copy ? 'h' : 'L';
  if (!want_args(c, n, types))
    return;
  int32_t cf = ctl ? as_i32(&c->raw[0]) : 0;
  int32_t a = as_i32(&c->raw[ctl ? 1 : 0]);
  wspec W = wspec_of(w);
  g_copy_xorc(c->sym, &W, is_copy, ctl, cf, a, is_copy ? as_i32(&c->raw[n - 1]) : 0, &c->raw[n - 1]);
}

static inline void g_push(int32_t v) {
  if (nstack == capstack) {
    capstack = capstack ? 2 * capstack : 256;
    stack_ = realloc(stack_, capstack * sizeof *stack_);
    if (!stack_)
      abort();
  }
  stack_[nstack++] = v;
  if (trace_all_())
    cqe__logf("{\"ev\":\"push\",\"word\":%d}", (int)v);
}

static void gate_push(call_t *c) {
  if (c->nargs != 1 || !c->ty[0].is_i32) {
    cqe__violation("malformed_call", -1, "%s: expected (i32)", c->sym);
    return;
  }
  g_push(as_i32(&c->raw[0]));
}

static inline int32_t g_pop(const char *sym) {
  int32_t w = 0;
  if (rp_floor_on && nstack <= rp_floor)
    cqe__rp_dirty = 1;
  if (nstack == 0)
    cqe__violation("pop_empty", -1, "%s: the word stack is empty", sym);
  else
    w = stack_[--nstack];
  if (trace_all_())
    cqe__logf("{\"ev\":\"pop\",\"word\":%d}", (int)w);
  return w;
}

static void gate_pop(call_t *c) {
  if (c->nargs != 0 || !c->rty->is_i32)
    cqe__violation("malformed_call", -1, "%s: expected () -> i32", c->sym);
  store_word(c->ret, c->rty, (uint32_t)g_pop(c->sym));
}

/* A cqrt_* core gate's name, parsed (cq-9hzgh: once per call site, dispatch_site). */
enum { G_FREE = 1, G_PUSH, G_POP, G_ALLOC, G_MEASURE, G_RY, G_RZ_I1, G_RZ_QANGLE, G_LOGIC, G_COPY_XORC };
typedef struct {
  int gate, q, ctl, is_copy, lop;
  uint32_t wbits; /* w's bits and kind as wspec_of gives them (the fast gates) */
  char wkind;
  uint16_t wi;    /* w's index in core.c's width table (cqe__wi_of), 0 none: the fused gates (r7-fuse) */
  char w[8];
  const char *name; /* the classification's gate: "free", "ry_qangle", "and", "copy", ... */
} core_cls;

/* Parse a cqrt_* name (without the prefix) as a core gate. 1 a core gate, 0 not. */
static int core_parse(const char *s, core_cls *k) {
  const char *r;
  int unc;
  memset(k, 0, sizeof *k);
  if (!strcmp(s, "free")) {
    k->gate = G_FREE, k->name = "free";
    return 1;
  }
  if (!strcmp(s, "push")) {
    k->gate = G_PUSH, k->name = "push";
    return 1;
  }
  if (!strcmp(s, "pop")) {
    k->gate = G_POP, k->name = "pop";
    return 1;
  }
  if (!strncmp(s, "alloc_", 6) && (r = take_w(s + 6, k->w, sizeof k->w)) && !*r) {
    k->gate = G_ALLOC, k->name = "alloc";
    return 1;
  }
  if (!strncmp(s, "measure_", 8) && (r = take_w(s + 8, k->w, sizeof k->w)) && !*r) {
    k->gate = G_MEASURE, k->name = "measure";
    return 1;
  }
  if (!strncmp(s, "ry_", 3) && (r = take_w(s + 3, k->w, sizeof k->w)) && !suffixes(r, 1, 1, 0, &k->q, &k->ctl, &unc)) {
    k->gate = G_RY, k->name = k->q ? "ry_qangle" : "ry";
    return 1;
  }
  if (!strcmp(s, "rz_i1")) {
    k->gate = G_RZ_I1, k->name = "rz_i1";
    return 1;
  }
  if (!strncmp(s, "rz_qangle", 9) && !suffixes(s + 9, 0, 1, 0, &k->q, &k->ctl, &unc)) {
    k->gate = G_RZ_QANGLE, k->name = "rz_qangle";
    return 1;
  }
  static const char *const logic[] = {"not", "and", "or", "xor"};
  for (int i = 0; i < 4; ++i) {
    size_t n = strlen(logic[i]);
    if (!strncmp(s, logic[i], n) && !strncmp(s + n, "_i1", 3) && !suffixes(s + n + 3, 0, 0, 1, &k->q, &k->ctl, &unc)) {
      k->gate = G_LOGIC, k->name = logic[i], k->lop = i; /* logic[] is in LOP_* order */
      return 1;
    }
  }
  int is_copy = !strncmp(s, "copy_", 5), is_xorc = !strncmp(s, "xorc_", 5);
  if ((is_copy || is_xorc) && (r = take_w(s + 5, k->w, sizeof k->w)) && !suffixes(r, 0, 1, 1, &k->q, &k->ctl, &unc)) {
    k->gate = G_COPY_XORC, k->is_copy = is_copy, k->name = is_copy ? "copy" : "xorc";
    return 1;
  }
  memset(k, 0, sizeof *k);
  return 0;
}

static void core_run(call_t *c, const core_cls *k) {
  if (cqe__rp_window && (k->gate == G_RY || k->gate == G_RZ_I1 || k->gate == G_RZ_QANGLE || k->gate == G_MEASURE))
    cqe__rp_dirty = 1; /* cq-kcn5i: never in a replayed clone (rt_replay.c) */
  switch (k->gate) {
  case G_FREE:
    gate_free(c);
    break;
  case G_PUSH:
    gate_push(c);
    break;
  case G_POP:
    gate_pop(c);
    break;
  case G_ALLOC:
    gate_alloc(c, k->w);
    break;
  case G_MEASURE:
    gate_measure(c, k->w);
    break;
  case G_RY:
    gate_ry(c, k->w, k->q, k->ctl);
    break;
  case G_RZ_I1:
    gate_rz_i1(c);
    break;
  case G_RZ_QANGLE:
    gate_rz_qangle(c, k->ctl);
    break;
  case G_LOGIC:
    gate_logic(c, k->lop);
    break;
  case G_COPY_XORC:
    gate_copy_xorc(c, k->w, k->is_copy, k->ctl);
    break;
  }
}

/* Route a cqrt_* core gate. 1 handled, 0 not a core gate. With c == NULL only classifies. */
static int core_gate(call_t *c, const char *s, char *cls, size_t ncls) {
  core_cls k;
  if (!core_parse(s, &k))
    return 0;
  if (cls)
    snprintf(cls, ncls, "core:%s", k.name);
  if (c)
    core_run(c, &k);
  return 1;
}

/* ---- family path ------------------------------------------------------------------------- */

static const char *const fam_stems[] = {"qram_alloc", "qram_store", "qram_load", "qram_swap", "tape_alloc",
                                        "tape_fmt",   "tape_effect", "tape_write", "abort",    NULL};

/* Parse a non-core cqrt_ name (without the prefix) into t. 0 ok. */
static int parse_family(const char *s, cqe_tname *t) {
  memset(t, 0, sizeof *t);
  size_t best = 0;
  for (const char *const *st = fam_stems; *st; ++st) {
    size_t n = strlen(*st);
    if (n > best && !strncmp(s, *st, n) && (s[n] == 0 || s[n] == '_'))
      best = n;
  }
  if (!best)
    return -1;
  memcpy(t->op, s, best);
  t->op[best] = 0;
  const char *p = s + best;
  if (*p == '_') {
    char w[8];
    const char *r = take_w(p + 1, w, sizeof w);
    if (r) {
      snprintf(t->w, sizeof t->w, "%s", w);
      p = r;
    }
  }
  if (!strncmp(p, "_hl", 3)) {
    snprintf(t->shape, sizeof t->shape, "hl");
    p += 3;
  } else if (!strncmp(p, "_lit", 4)) {
    snprintf(t->shape, sizeof t->shape, "l");
    p += 4;
  }
  if (!strncmp(p, "_controlled", 11)) {
    snprintf(t->pred, sizeof t->pred, "ctl");
    p += 11;
  }
  if (!strncmp(p, "_unc", 4)) {
    t->unc = 1;
    p += 4;
  }
  return *p ? -1 : 0;
}

uint32_t cqe__nrails_peek(void);

/* ---- call sites (cq-9hzgh) ------------------------------------------------------------------
 * Everything the dispatcher reads from a runtime symbol's name and signature, parsed once per call site:
 * at its first call, or for every site of the program when the batch runner starts (cqe__sites_resolve,
 * before the setup's snapshot, so a sample parses none again). The per-call path below does what the
 * parsing entry did on every call, from these fields, with the same checks and violations in the same
 * order. */
enum { R_BADSIG = 1, R_INV_BEGIN, R_INV_END, R_TEMPLATE, R_CORE, R_FAMILY, R_UNKNOWN_CQRT, R_UNKNOWN };

static int parse_sig(const char *sig, lty *rty, lty *ty, int *n);

typedef struct site_res site_res;
/* A call site's gate over its argument words (cq-r6-dispatch; fast_pick): the result as the stub returns it. */
struct cqe_site_;
typedef uint64_t (*fast_fn)(struct cqe_site_ *s, site_res *R, const uint64_t *a);
struct site_res {
  int route, nargs;
  fast_fn fast;    /* non-NULL: the site's signature is its core gate's own, every value of at most 64 bits */
  int small;       /* every parameter and the result fit a word: the word entry (cqe_cw) can marshal the call */
  int fam_qram, fam_abort, fam_tape_write; /* R_FAMILY: t.op is qram_*, "abort", "tape_write" */
  int and_hl32;    /* a parsed template and_i32_hl (rule 23, template_call) */
  lty rty;
  int rty_i32;
  core_cls core;   /* R_CORE */
  cqe_tname t;     /* R_TEMPLATE (tok: parsed) and R_FAMILY */
  int tok;
  int off, nf, layout_ok; /* a parsed template: */
  char mask[66];
  const char *rw;  /* its result width token (result_w) */
  uint32_t rbits;
  char rkind;
  uint16_t rwi;    /* rw's index in core.c's width table (cqe__wi_of), 0 none (r7-fuse: fast_template) */
  hlist handlers;  /* the handlers registered for t.op */
  lty ty[];        /* nargs parameter types */
};

static fast_fn fast_pick(const site_res *R);
static int fast_template_ok(const site_res *R);
static uint64_t fast_template(struct cqe_site_ *s, site_res *R, const uint64_t *a);

/* A stub's call site (stubgen.py emits one per runtime symbol it defines, internal to the program). */
typedef struct cqe_site_ {
  const char *sym, *sig;
  int32_t nargs, pad_;
  site_res *res; /* NULL until resolved */
} cqe_site;

static site_res *site_resolve(const char *sym, const char *sig, int32_t nargs) {
  int na = nargs > 0 && nargs <= 64 ? nargs : 0;
  site_res *r = calloc(1, sizeof *r + (size_t)(na ? na : 1) * sizeof(lty));
  if (!r)
    abort();
  r->nargs = nargs;
  /* iv_intercept's markers come before the signature is read */
  if (!strcmp(sym, "cqrt_invert_begin")) {
    r->route = R_INV_BEGIN;
    return r;
  }
  if (!strcmp(sym, "cqrt_invert_end")) {
    r->route = R_INV_END;
    return r;
  }
  int n = nargs;
  if (nargs < 0 || nargs > 64 || parse_sig(sig, &r->rty, r->ty, &n)) {
    r->route = R_BADSIG;
    return r;
  }
  r->rty_i32 = !strcmp(r->rty.ty, "i32");
  if (!strncmp(sym, "cq_template_", 12)) {
    r->route = R_TEMPLATE;
    r->tok = cqe_parse_template(sym, &r->t) == 0;
    if (r->tok) {
      r->off = r->t.unc ? 1 : 0;
      r->nf = nargs - r->off;
      r->rw = result_w(&r->t);
      r->rbits = cqe__wtok_bits(r->rw, &r->rkind);
      r->layout_ok = cqe__template_layout(&r->t, r->nf, r->mask) == 0;
      r->and_hl32 = !strcmp(r->t.op, "and") && r->nf == 2 && r->layout_ok && r->mask[0] == 'h' && r->mask[1] == 'l' &&
                    r->rbits == 32;
      r->rwi = r->rbits ? cqe__wi_of(r->rw) : 0;
    }
  } else if (!strncmp(sym, "cqrt_", 5)) {
    if (core_parse(sym + 5, &r->core))
      r->route = R_CORE;
    else if (parse_family(sym + 5, &r->t) == 0) {
      r->route = R_FAMILY;
      r->fam_qram = !strncmp(r->t.op, "qram_", 5);
      r->fam_abort = !strcmp(r->t.op, "abort");
      r->fam_tape_write = !strcmp(r->t.op, "tape_write");
    } else
      r->route = R_UNKNOWN_CQRT;
  } else {
    r->route = R_UNKNOWN;
  }
  if (r->route == R_CORE && r->core.w[0]) {
    wspec W = wspec_of(r->core.w);
    r->core.wbits = W.bits, r->core.wkind = W.kind;
    r->core.wi = cqe__wi_of(r->core.w);
  }
  r->small = r->rty.kind == 'v' || r->rty.bits <= 64;
  for (int i = 0; i < nargs; ++i)
    if (r->ty[i].bits > 64)
      r->small = 0;
  r->fast = fast_pick(r);
  return r;
}

static void family_call(call_t *c, site_res *R) {
  const cqe_tname *t = &R->t;
  hlist *hl = &R->handlers;
  if (cqe__rp_window && !R->fam_qram) /* cq-kcn5i: tape, abort: never in a replayed clone */
    cqe__rp_dirty = 1;
  cqe_val out;
  uint64_t oinl;
  val_in(&out, c->rty->kind == 'v' ? 0 : c->rty->bits, c->rty->kind == 'f' ? 'f' : 'i', &oinl);
  if (R->fam_abort && c->nargs >= 1 && cqe__exists(as_i32(&c->raw[0])))
    cqe__setrole(as_i32(&c->raw[0]), 1);
  /* rails the family creates during this call get the family's exit role */
  int32_t before = (int32_t)cqe__nrails_peek();
  int r = run_handlers(c->sym, t, c->raw, c->nargs, &out, hl);
  int32_t after = (int32_t)cqe__nrails_peek() + 1;
  int role = R->fam_tape_write ? 2 : 0;
  if (role)
    for (int32_t h = before + 1; h < after; ++h)
      cqe__setrole(h, role);
  if (r == 0)
    store_val(c->ret, c->rty, &out);
  val_drop(&out, &oinl);
}

/* ---- template path ----------------------------------------------------------------------- */

static void template_call(call_t *c, const char *sym, site_res *R) {
  int is_i32_ret = R->rty_i32;
  if (!R->tok) {
    cqe__violation("bad_template", -1, "%s: not a template name (CR §1.2)", sym);
    if (is_i32_ret)
      store_word(c->ret, c->rty, (uint32_t)cqe__new("i1", NULL, 0, 0));
    return;
  }
  const cqe_tname *t = &R->t;
  int off = R->off, nf = R->nf;
  const char *mask = R->mask;
  const char *rw = R->rw;
  char rkind = R->rkind;
  uint32_t rbits = R->rbits;
  int ok = R->layout_ok;
  if (!ok)
    cqe__violation("malformed_call", -1, "%s: %d forward arguments do not fit the name", sym, nf);
  if (t->unc && (c->nargs < 1 || !c->ty[0].is_i32 || c->rty->kind != 'v')) {
    cqe__violation("malformed_call", -1, "%s: an _unc takes (i32 out, args...) and returns void", sym);
    ok = 0;
  }
  if (!t->unc && !is_i32_ret) {
    cqe__violation("malformed_call", -1, "%s: a forward template returns an i32 handle", sym);
    ok = 0;
  }
  for (int i = 0; ok && i < nf; ++i)
    if (mask[i] == 'h' && !c->ty[off + i].is_i32) {
      cqe__violation("malformed_call", -1, "%s: handle argument %d is %s", sym, i, c->ty[off + i].ty);
      ok = 0;
    }
  /* resolve operands */
  int full = cqe__trace_all(); /* the tmpl/unc event is written (cq-9hzgh) */
  cqe_val args[64];
  uint64_t ainl[64];
  char owned[64];
  int nres = 0; /* arguments resolved: args[i] and owned[i] are set for i < nres (nothing is zeroed ahead) */
  int32_t hs[66];
  int nh = 0, known = 1;
  sbuf ab = {0};
  if (full)
    sb_add(&ab, "[");
  for (int i = 0; ok && i < nf; ++i) {
    const cqe_val *raw = &c->raw[off + i];
    if (i && full)
      sb_add(&ab, ",");
    if (mask[i] == 'h') {
      int32_t h = as_i32(raw);
      if (cqe__check(h, sym) < 0) {
        ok = 0;
        break;
      }
      hs[nh++] = h;
      known = known && cqe__known(h);
      const cqe_val *rv = cqe__val(h); /* M1: a copy of the rail's value */
      val_in(&args[i], rv->bits, rv->kind, &ainl[i]);
      if (args[i].nw == 1) { /* cqe__val_copy_into for one word */
        ainl[i] = rv->nw ? rv->w[0] : 0;
        vmask_(&args[i]);
      } else {
        cqe__val_copy_into(&args[i], rv);
      }
      owned[i] = 1;
      if (full) {
        sb_addf(&ab, "{\"h\":%d,\"v\":\"", (int)h);
        sb_hex(&ab, cqe__val(h));
        sb_add(&ab, "\"}");
      }
    } else {
      args[i] = *raw;
      owned[i] = 0;
      if (full) {
        sb_add(&ab, "{\"lit\":\"");
        sb_hex(&ab, raw);
        sb_add(&ab, "\"}");
      }
    }
    nres = i + 1;
  }
  if (full)
    sb_add(&ab, "]");
  cqe_val out;
  uint64_t oinl;
  val_in(&out, rbits ? rbits : 1, rkind ? rkind : 'i', &oinl);
  int r = ok ? run_handlers(sym, t, args, nf, &out, &R->handlers) : -1;
  if (r == 0 && out.bits != (rbits ? rbits : 1)) {
    cqe__violation("result_width", -1, "%s: handler produced %u bits, the name implies %u", sym, out.bits, rbits);
    r = -1;
  }
  if (r != 0)
    memset(out.w, 0, out.nw * sizeof *out.w);
  out.bits = rbits ? rbits : 1;
  /* rule 23 (cq-tt2j): an _rmq template's last operand is the mode rail; an _exc result is flags */
  if (ok && t->rm == 2 && nf > 0 && mask[nf - 1] == 'h')
    cqe__setfenv(as_i32(&c->raw[off + nf - 1]), 2);
  if (!t->unc) {
    int32_t o = cqe__new(rw, &out, known && r == 0, 0);
    if (t->exc)
      cqe__setfenv(o, 1);
    /* rule 23: a memory fenv object's fields read as the new state: and_i32_hl(field, 63 | 0xC00) */
    if (R->and_hl32) {
      int32_t lit = as_i32(&c->raw[off + 1]);
      if (lit == 63 || lit == 3072)
        cqe__setfenv(o, lit == 63 ? 1 : 2);
    }
    for (int i = 0; i < nh; ++i)
      cqe__add_dep(o, hs[i]);
    if (full) {
      sbuf b = {0};
      sb_addf(&b, "{\"ev\":\"tmpl\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"w\":\"%s\",\"v\":\"", sym, (int)o, ab.p, rw);
      sb_hex(&b, cqe__val(o));
      sb_addf(&b, "\",\"known\":%s}", cqe__known(o) ? "true" : "false");
      cqe_log(b.p);
      free(b.p);
    }
    store_word(c->ret, c->rty, (uint32_t)o);
  } else if (c->nargs >= 1) {
    int32_t o = as_i32(&c->raw[0]);
    if (cqe__check(o, sym) == 0) {
      if (!streq_(cqe__w(o), rw))
        cqe__violation("width_mismatch", o, "%s: out rail %d is %s, the name implies %s", sym, (int)o, cqe__w(o), rw);
      vxor_(cqe__val(o), &out);
      cqe__carry(o, hs, nh);
      cqe__r6_unc(o, hs, nh);
      cqe__mark_written(o);
      if (full) {
        sbuf b = {0};
        sb_addf(&b, "{\"ev\":\"unc\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"residue\":\"", sym, (int)o, ab.p);
        sb_hex(&b, cqe__val(o));
        sb_add(&b, "\"}");
        cqe_log(b.p);
        free(b.p);
      }
      if (!viszero_(cqe__val(o))) {
        char *hx = cqe__hexa(cqe__val(o));
        cqe__violation("unc_residue", o, "%s: out rail %d holds %s after its _unc", sym, (int)o, hx);
        free(hx);
        cqe__setknown(o, 0);
      } else if (!zero_rule_(o, hs, nh) || r != 0) {
        if (r == 0)
          cqe__violation("unc_after_nondiagonal", o,
                         "%s: rail %d or an operand took a non-diagonal gate after rail %d was computed", sym, (int)o,
                         (int)o);
        cqe__setknown(o, 0);
      }
    }
  }
  free(ab.p);
  for (int i = 0; i < nres; ++i)
    if (owned[i])
      val_drop(&args[i], &ainl[i]);
  val_drop(&out, &oinl);
}

/* ---- entry ------------------------------------------------------------------------------- */

/* "<ret>|<t0>,<t1>,..." with exactly n parameter types (n < 0: as many as there are, *n set). */
static int parse_sig(const char *sig, lty *rty, lty *ty, int *n) {
  const char *bar = strchr(sig, '|');
  if (!bar || parse_lty(sig, (size_t)(bar - sig), rty))
    return -1;
  const char *p = bar + 1;
  int want = *n, i = 0;
  while (want < 0 ? *p != 0 : i < want) {
    if (i >= 64)
      return -1;
    const char *e = strchr(p, ',');
    size_t len = e ? (size_t)(e - p) : strlen(p);
    if (parse_lty(p, len, &ty[i]) || ty[i].kind == 'v')
      return -1;
    ++i;
    p += len + (e ? 1 : 0);
  }
  if (*p != 0)
    return -1;
  *n = i;
  return 0;
}

static int iv_intercept(const char *sym, const char *sig, const char *csig, int32_t nargs, void **argv, void *ret,
                        void *thunk);
static size_t iv_nopen;
static int iv_replaying;

uint64_t cqe__ncalls; /* runtime calls dispatched (rt_replay.c's statistics, cq-kcn5i) */

/* The call c of a resolved site, by its route. */
static inline void route_call(call_t *c, const char *sym, site_res *R) {
  switch (R->route) {
  case R_TEMPLATE:
    template_call(c, sym, R);
    break;
  case R_CORE:
    core_run(c, &R->core);
    break;
  case R_FAMILY:
    family_call(c, R);
    break;
  case R_UNKNOWN_CQRT:
    cqe__violation("unknown_symbol", -1, "%s: not a cqrt_* symbol of BACKEND_ABI §1", sym);
    break;
  default:
    cqe__violation("unknown_symbol", -1, "%s: not a runtime symbol", sym);
    break;
  }
}

/* One call of a runtime symbol through its resolved site, its arguments in memory. */
static void dispatch_res(const char *sym, const char *sig, site_res *R, int32_t nargs, void **argv, void *ret) {
  cqe__init();
  ++cqe__ncalls;
  if ((R->route == R_INV_BEGIN || R->route == R_INV_END || (iv_nopen && !iv_replaying)) &&
      iv_intercept(sym, sig, NULL, nargs, argv, ret, NULL))
    return; /* cq_invert (BACKEND_ABI 1.13): a marker, or a gate recorded in an open region */
  if (R->route == R_BADSIG) {
    cqe__violation("malformed_call", -1, "%s: bad stub signature '%s'", sym, sig);
    return;
  }
  const lty *ty = R->ty;
  cqe_val raw[64];
  uint64_t rinl[64];
  for (int i = 0; i < nargs; ++i)
    load_val_in(&raw[i], &ty[i], argv[i], &rinl[i]);
  if (R->rty.kind != 'v')
    store_word(ret, &R->rty, 0);
  call_t c = {sym, nargs, ty, raw, &R->rty, ret};
  route_call(&c, sym, R);
  for (int i = 0; i < nargs; ++i)
    val_drop(&raw[i], &rinl[i]);
}

/* A symbol given by name and signature (a replayed cq_invert gate, a test): resolved for this call. */
void cqe_dispatch(const char *sym, const char *sig, int32_t nargs, void **argv, void *ret) {
  cqe__init();
  site_res *R = site_resolve(sym, sig, nargs);
  dispatch_res(sym, sig, R, nargs, argv, ret);
  free(R);
}

/* The entry of a stub whose signature has a value wider than a word (stubgen.py; cq-9hzgh): its site, resolved once,
 * the arguments in memory. */
void cqe_call(cqe_site *s, void **argv, void *ret) {
  cqe__init();
  if (!s->res)
    s->res = site_resolve(s->sym, s->sig, s->nargs);
  dispatch_res(s->sym, s->sig, s->res, s->nargs, argv, ret);
}

/* ---- the word entry (cq-r6-dispatch) ----------------------------------------------------------
 * A stub whose parameters and result all fit 64 bits (every i1 and small-width gate, alloc, free, push, pop, and
 * the templates and bus accesses of such widths) passes its arguments as words, a[i] the i-th argument zero-extended
 * (an fp value by its bits, a ptr by its address), and returns the word cqe_cw returns, truncated to its result type.
 * What cqe_call does per call from the stub's memory, cqe_cw does from the words: no argument array of 64 values, no
 * copy in or out. A site with fast set (fast_pick: a core gate whose stub signature is the gate's own) runs its gate
 * with nothing between: every check of the signature was made once, when the site was resolved, and every check
 * of the operands is the gate's own body (g_*), the one the generic entry runs. */
static uint64_t fast_free(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  (void)R;
  if (!cqe__f_free((uint32_t)a[0]))
    g_free(sym, (int32_t)(uint32_t)a[0]);
  return 0;
}
static uint64_t fast_push(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  (void)R, (void)sym;
  g_push((int32_t)(uint32_t)a[0]);
  return 0;
}
static uint64_t fast_pop(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  (void)R, (void)a;
  return (uint32_t)g_pop(sym);
}
static uint64_t fast_alloc(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  (void)sym;
  uint64_t x = a[0] & R->ty[0].mask;
  cqe_val lit = {R->ty[0].bits, R->ty[0].kind == 'f' ? 'f' : 'i', 1, &x};
  int32_t h = R->core.wi ? cqe__f_alloc(R->core.wi, x) : 0;
  if (!h)
    return (uint32_t)g_alloc(R->core.w, &lit);
  if (trace_all_()) { /* g_alloc's event */
    char *hx = cqe__hexa(cqe__val(h));
    cqe__logf("{\"ev\":\"alloc\",\"h\":%d,\"w\":\"%s\",\"v\":\"%s\",\"known\":true}", (int)h, R->core.w, hx);
    free(hx);
  }
  return (uint32_t)h;
}
static uint64_t fast_logic(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  int n = R->nargs;
  int32_t hs[3];
  for (int i = 0; i < n; ++i)
    hs[i] = (int32_t)(uint32_t)a[i];
  if (!cqe__f_logic(R->core.lop == LOP_AND, n, a))
    g_logic(sym, R->core.lop, n, hs);
  else
    log_gate_(sym, hs[n - 1], hs, n - 1);
  return 0;
}
static uint64_t fast_copy(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  int ctl = R->core.ctl;
  if (R->core.wi && cqe__f_copy(R->core.wi, ctl, a)) {
    int32_t srcs[2] = {(int32_t)(uint32_t)a[ctl], ctl ? (int32_t)(uint32_t)a[0] : 0};
    log_gate_(sym, (int32_t)(uint32_t)a[ctl + 1], srcs, 1 + ctl);
    return 0;
  }
  wspec W = {R->core.w, R->core.wbits, R->core.wkind};
  g_copy_xorc(sym, &W, 1, ctl, ctl ? (int32_t)(uint32_t)a[0] : 0, (int32_t)(uint32_t)a[ctl], (int32_t)(uint32_t)a[ctl + 1], NULL);
  return 0;
}
static uint64_t fast_xorc(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  int ctl = R->core.ctl;
  uint64_t x = a[ctl + 1] & R->ty[ctl + 1].mask;
  if (R->core.wi && cqe__f_xorc(R->core.wi, ctl, a, x)) {
    int32_t srcs[1] = {ctl ? (int32_t)(uint32_t)a[0] : 0};
    log_gate_(sym, (int32_t)(uint32_t)a[ctl], srcs, ctl);
    return 0;
  }
  cqe_val lit = {R->ty[ctl + 1].bits, R->ty[ctl + 1].kind == 'f' ? 'f' : 'i', 1, &x};
  wspec W = {R->core.w, R->core.wbits, R->core.wkind};
  g_copy_xorc(sym, &W, 0, ctl, ctl ? (int32_t)(uint32_t)a[0] : 0, (int32_t)(uint32_t)a[ctl], 0, &lit);
  return 0;
}

/* The fast gate of a resolved site, or NULL: only where the generic entry's signature checks (want_args and the
 * gates' own) all pass, so that it has no violation to write before the gate's body. */
static fast_fn fast_pick(const site_res *R) {
  if (R->route == R_TEMPLATE)
    return fast_template_ok(R) ? fast_template : NULL;
  if (R->route != R_CORE || !R->small)
    return NULL;
  const core_cls *k = &R->core;
  int n = R->nargs;
  switch (k->gate) {
  case G_FREE:
    return n == 1 && R->ty[0].is_i32 ? fast_free : NULL;
  case G_PUSH:
    return n == 1 && R->ty[0].is_i32 ? fast_push : NULL;
  case G_POP:
    return n == 0 && R->rty.is_i32 ? fast_pop : NULL;
  case G_ALLOC:
    return n == 1 && R->rty.is_i32 ? fast_alloc : NULL;
  case G_LOGIC:
    if (n != logic_n(k->lop))
      return NULL;
    for (int i = 0; i < n; ++i)
      if (!R->ty[i].is_i32)
        return NULL;
    return fast_logic;
  case G_COPY_XORC:
    if (n != (k->ctl ? 3 : 2) || (k->ctl && !R->ty[0].is_i32) || !R->ty[k->ctl].is_i32 ||
        (k->is_copy && !R->ty[k->ctl + 1].is_i32))
      return NULL;
    return k->is_copy ? fast_copy : fast_xorc;
  default:
    return NULL;
  }
}

/* A counted call of a small site with no cq_invert region open, marshalled from the words to its route. */
__attribute__((noinline)) static uint64_t words_route(cqe_site *s, site_res *R, const uint64_t *a) {
  int32_t nargs = s->nargs;
  uint64_t ret = 0;
  const lty *ty = R->ty;
  cqe_val raw[64];
  uint64_t rinl[64];
  for (int i = 0; i < nargs; ++i) {
    rinl[i] = a[i] & ty[i].mask;
    raw[i] = (cqe_val){ty[i].bits, ty[i].kind == 'f' ? 'f' : 'i', 1, &rinl[i]};
  }
  call_t c = {s->sym, nargs, ty, raw, &R->rty, &ret};
  route_call(&c, s->sym, R);
  return ret;
}

/* A template call of one-word values over its operands' records (r7-fuse; core.c "fused gates"). fast_template_ok says
 * the site passes every check template_call makes of the name and the signature, so that none of its violations is due
 * before the operands are read; a call whose operands are not all live one-word rails (cqe__f_ops) goes to
 * template_call unchanged. Otherwise this is template_call step by step: the operand values, the handlers, then the
 * result rail (cqe__f_tnew) or the out rail's XOR, residue and known-basis rule (cqe__f_tunc), and the same events
 * and violations in the same order. */
#define FT_MAX 8
static int fast_template_ok(const site_res *R) {
  const cqe_tname *t = &R->t;
  if (!R->small || !R->tok || !R->layout_ok || R->nf > FT_MAX || !R->rwi || R->rbits > 64 || t->exc || t->rm == 2 ||
      R->and_hl32)
    return 0;
  if (t->unc ? (R->nargs < 1 || !R->ty[0].is_i32 || R->rty.kind != 'v') : !R->rty_i32)
    return 0;
  for (int i = 0; i < R->nf; ++i)
    if (R->mask[i] == 'h' && !R->ty[R->off + i].is_i32)
      return 0;
  return 1;
}
static uint64_t fast_template(cqe_site *s, site_res *R, const uint64_t *a) {
  const char *sym = s->sym;
  const cqe_tname *t = &R->t;
  int off = R->off, nf = R->nf, nh = 0, known = 1;
  uint32_t hs[FT_MAX], hb[FT_MAX];
  uint64_t hv[FT_MAX], ainl[FT_MAX];
  char hk[FT_MAX];
  void *recs[FT_MAX], *orec = NULL;
  for (int i = 0; i < nf; ++i)
    if (R->mask[i] == 'h')
      hs[nh++] = (uint32_t)a[off + i];
  if (!cqe__f_ops(nh, hs, recs, hv, hb, hk, &known, t->unc, t->unc ? (uint32_t)a[0] : 0, R->rwi, &orec))
    return words_route(s, R, a);
  int full = trace_all_();
  cqe_val args[FT_MAX];
  sbuf ab = {0};
  if (full)
    sb_add(&ab, "[");
  for (int i = 0, k = 0; i < nf; ++i) {
    if (i && full)
      sb_add(&ab, ",");
    if (R->mask[i] == 'h') {
      cqe_val rv = {hb[k], hk[k], 1, &hv[k]};
      ainl[i] = hv[k];
      args[i] = (cqe_val){hb[k], hk[k], 1, &ainl[i]};
      vmask_(&args[i]);
      if (full) {
        sb_addf(&ab, "{\"h\":%d,\"v\":\"", (int)hs[k]);
        sb_hex(&ab, &rv);
        sb_add(&ab, "\"}");
      }
      ++k;
    } else {
      const lty *ty = &R->ty[off + i];
      ainl[i] = a[off + i] & ty->mask;
      args[i] = (cqe_val){ty->bits, ty->kind == 'f' ? 'f' : 'i', 1, &ainl[i]};
      if (full) {
        sb_add(&ab, "{\"lit\":\"");
        sb_hex(&ab, &args[i]);
        sb_add(&ab, "\"}");
      }
    }
  }
  if (full)
    sb_add(&ab, "]");
  uint32_t rbits = R->rbits;
  uint64_t oinl = 0;
  cqe_val out = {rbits, R->rkind ? R->rkind : 'i', 1, &oinl};
  int r = run_handlers(sym, t, args, nf, &out, &R->handlers);
  if (r == 0 && out.bits != rbits) {
    cqe__violation("result_width", -1, "%s: handler produced %u bits, the name implies %u", sym, out.bits, rbits);
    r = -1;
  }
  if (r != 0)
    oinl = 0;
  uint64_t ret = 0;
  if (!t->unc) {
    int32_t o = cqe__f_tnew(R->rwi, oinl, known && r == 0, nh, hs, recs);
    if (full) {
      sbuf b = {0};
      sb_addf(&b, "{\"ev\":\"tmpl\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"w\":\"%s\",\"v\":\"", sym, (int)o, ab.p, R->rw);
      sb_hex(&b, cqe__val(o));
      sb_addf(&b, "\",\"known\":%s}", cqe__known(o) ? "true" : "false");
      cqe_log(b.p);
      free(b.p);
    }
    ret = (uint32_t)o;
  } else {
    int32_t o = (int32_t)(uint32_t)a[0];
    int st = cqe__f_tunc((uint32_t)o, orec, oinl, r == 0, nh, hs, recs);
    if (full) {
      sbuf b = {0};
      sb_addf(&b, "{\"ev\":\"unc\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"residue\":\"", sym, (int)o, ab.p);
      sb_hex(&b, cqe__val(o));
      sb_add(&b, "\"}");
      cqe_log(b.p);
      free(b.p);
    }
    if (st == 1) {
      char *hx = cqe__hexa(cqe__val(o));
      cqe__violation("unc_residue", o, "%s: out rail %d holds %s after its _unc", sym, (int)o, hx);
      free(hx);
    } else if (st == 2) {
      cqe__violation("unc_after_nondiagonal", o, "%s: rail %d or an operand took a non-diagonal gate after rail %d was computed",
                     sym, (int)o, (int)o);
    }
  }
  free(ab.p);
  return ret;
}

/* cqe_cw for every other site: the call marshalled from the words. */
__attribute__((noinline)) static uint64_t call_words(cqe_site *s, site_res *R, const uint64_t *a) {
  cqe__init();
  int32_t nargs = s->nargs;
  uint64_t ret = 0;
  int marker = R->route == R_INV_BEGIN || R->route == R_INV_END || R->route == R_BADSIG;
  if (!marker && !R->small) { /* stubgen.py never emits it */
    ++cqe__ncalls;
    cqe__violation("malformed_call", -1, "%s: a value wider than 64 bits through the word entry", s->sym);
    return 0;
  }
  if (marker || (iv_nopen && !iv_replaying)) {
    /* a cq_invert marker, a bad signature or a gate an open region may record: the memory entry (a word is its
     * value's memory, little-endian) */
    void *argv[64];
    for (int i = 0; i < nargs && i < 64; ++i)
      argv[i] = (void *)(uintptr_t)&a[i];
    dispatch_res(s->sym, s->sig, R, nargs, argv, &ret);
    return ret;
  }
  ++cqe__ncalls;
  return words_route(s, R, a);
}

uint64_t cqe_cw(cqe_site *s, const uint64_t *a) {
  site_res *R = s->res;
  if (__builtin_expect(!R, 0)) {
    cqe__init();
    R = s->res = site_resolve(s->sym, s->sig, s->nargs);
  }
  if (R->fast && !iv_nopen) {
    ++cqe__ncalls;
    return R->fast(s, R, a);
  }
  return call_words(s, R, a);
}

/* The program's sites (stubgen.py's constructor hands them over); cqe__sites_resolve resolves every one
 * (core.c, when the batch runner starts: after every family registered, before the setup's snapshot). */
static cqe_site **sites_;
static int32_t nsites_;

void cqe_sites(cqe_site **tab, int32_t n) {
  sites_ = tab;
  nsites_ = n;
}

void cqe__sites_resolve(void) {
  for (int32_t i = 0; i < nsites_; ++i) {
    cqe_site *s = sites_[i];
    if (!s->res)
      s->res = site_resolve(s->sym, s->sig, s->nargs);
    if ((s->res->route == R_TEMPLATE && s->res->tok) || s->res->route == R_FAMILY)
      hlist_fill(&s->res->handlers, s->res->t.op);
  }
}

/* ---- rule 27 declared clones: the checker's stand-in (cq-rft) ---------------------------- */

/* The rail width token of a C scalar type. */
static const char *lty_wtok(const lty *t, char *buf, size_t n) {
  if (t->kind == 'i')
    snprintf(buf, n, "i%u", t->bits);
  else if (!strcmp(t->ty, "half"))
    snprintf(buf, n, "f16");
  else if (!strcmp(t->ty, "bfloat"))
    snprintf(buf, n, "bf16");
  else if (!strcmp(t->ty, "float"))
    snprintf(buf, n, "f32");
  else if (!strcmp(t->ty, "double"))
    snprintf(buf, n, "f64");
  else if (!strcmp(t->ty, "x86_fp80"))
    snprintf(buf, n, "f80");
  else
    return NULL;
  return buf;
}

/* Entry of every stub stubgen.py generates for a clone __cq_q_<fn>_<mask>[_t][_ctl][_pure][_unc] that
 * nothing links. csig is "<fn>|<ret>|<t0>,..." of the C function fn. Its ABI arguments (CR §1.4, rule 27):
 * [pred, _ctl] [out handle, a twin of a non-void fn] then per C parameter one scalar: an i32 handle when its
 * mask digit is 1 (a pointer: a handle to a 64-bit address rail), else the C-typed value (a pointer: a
 * classical ptr), then, for a table clone (_t, the declared clone of rule 27), the i32 K. The value is the
 * cq_standin.h function of fn and the non-pointer scalar arguments (a quantum one by its rail's value), the
 * same function the C oracle defines fn with. The forward clone returns a fresh rail holding it, a classical
 * result as a seed rail (void: no effect); its _ctl form ignores pred (the stand-in has no effect to guard,
 * rule 27); the twin XORs it out of the out rail (void: no effect) and, for a table clone, frees that rail
 * (§1.4: "frees the results it zeroes"; the caller frees no result of a table clone). A pointer result is a
 * rail holding null. */
typedef void (*standin_thunk)(void **cargs, void *cret);

static void standin(const char *sym, const char *sig, const char *csig, int32_t nargs, void **argv, void *ret,
                    standin_thunk thunk);

void cqe_standin(const char *sym, const char *sig, const char *csig, int32_t nargs, void **argv, void *ret) {
  standin(sym, sig, csig, nargs, argv, ret, NULL);
}

/* A declared clone whose fn the host defines (cq-aou6; stubgen.py): the C oracle links the host's fn, so
 * the clone takes its value from thunk, which calls that host fn on the C-typed argument values (one
 * pointer per C parameter; only scalar parameters) and stores its result; everything else is
 * cqe_standin's. A void fn is called by the forward clone only. */
void cqe_standin_host(const char *sym, const char *sig, const char *csig, int32_t nargs, void **argv, void *ret,
                      void *thunk) {
  standin(sym, sig, csig, nargs, argv, ret, (standin_thunk)thunk);
}

static void standin(const char *sym, const char *sig, const char *csig, int32_t nargs, void **argv, void *ret,
                    standin_thunk thunk) {
  cqe__init();
  if (cqe__rp_window) /* cq-kcn5i: a host call, never in a replayed clone */
    cqe__rp_dirty = 1;
  if (iv_intercept(sym, sig, csig, nargs, argv, ret, (void *)thunk))
    return; /* a declared clone's XOR into its result rail, recorded in an open cq_invert region */
  _Alignas(16) uint8_t cbuf[64][16]; /* the C arguments of fn, for thunk */
  _Alignas(16) uint8_t rbuf[16];
  void *cargs[64];
  lty rty, ty[64], crty, cty[64];
  int n = nargs, nc = -1;
  const char *bar = strchr(csig, '|');
  char fn[256];
  if (nargs < 0 || nargs > 64 || parse_sig(sig, &rty, ty, &n) || !bar || (size_t)(bar - csig) >= sizeof fn ||
      parse_sig(bar + 1, &crty, cty, &nc)) {
    cqe__violation("malformed_call", -1, "%s: bad stand-in stub signature '%s' / '%s'", sym, sig, csig);
    return;
  }
  memcpy(fn, csig, (size_t)(bar - csig));
  fn[bar - csig] = 0;
  cqe_val raw[64];
  for (int i = 0; i < nargs; ++i)
    load_val(&raw[i], &ty[i], argv[i]);
  if (rty.kind != 'v') {
    cqe_val z;
    cqe__val_init(&z, rty.bits, 'i');
    store_val(ret, &rty, &z);
    cqe__val_free(&z);
  }

  /* the name: __cq_q_ fn _ mask { _suffix } */
  size_t fl = strlen(fn);
  int ok = !strncmp(sym, "__cq_q_", 7) && !strncmp(sym + 7, fn, fl) && sym[7 + fl] == '_';
  const char *mask = ok ? sym + 8 + fl : "";
  size_t ml = strspn(mask, "01");
  int unc = 0, ctl = 0, table = 0;
  if (!strncmp(mask, "v", 1) && (mask[1] == 0 || mask[1] == '_'))
    ml = 0; /* §1.4: a function with no scalar formal */
  const char *sfx = mask + ml + (ml == 0 && *mask == 'v' ? 1 : 0);
  for (const char *q = sfx; ok && *q;) {
    if (*q != '_') {
      ok = 0;
      break;
    }
    const char *e = strchr(q + 1, '_');
    size_t len = e ? (size_t)(e - q - 1) : strlen(q + 1);
    if (len == 3 && !strncmp(q + 1, "unc", 3))
      unc = 1;
    else if (len == 3 && !strncmp(q + 1, "ctl", 3))
      ctl = 1;
    else if (len == 1 && q[1] == 't')
      table = 1;
    else if (!(len == 4 && !strncmp(q + 1, "pure", 4)))
      ok = 0;
    q += 1 + len;
  }
  if (!ok || (ml == 0 && nc != 0)) {
    cqe__violation("malformed_call", -1, "%s: not a declared clone of %s (CR §1.4, rule 27)", sym, fn);
    goto done;
  }

  /* walk the ABI arguments against the C signature and the mask */
  {
    int a = 0, d = 0, nh = 0, known = 1;
    int32_t out_h = -1, hs[64];
    uint64_t h = cq_standin_name(fn, fl);
    sbuf ab = {0};
    sb_add(&ab, "[");
    if (unc ? rty.kind != 'v' : (crty.kind == 'v' ? rty.kind != 'v' : strcmp(rty.ty, "i32") != 0)) {
      cqe__violation("malformed_call", -1, "%s: returns %s; rule 27 says %s", sym, rty.ty,
                     (unc || crty.kind == 'v') ? "void" : "an i32 handle");
      ok = 0;
    }
    if (ok && ctl) { /* §1.4: _ctl_unc(pred, outs..., args...) */
      if (a >= nargs || strcmp(ty[a].ty, "i32") != 0 || cqe__check(as_i32(&raw[a]), sym) < 0)
        ok = 0;
      ++a;
    }
    if (ok && unc && crty.kind != 'v') {
      if (a >= nargs || strcmp(ty[a].ty, "i32") != 0)
        ok = 0;
      else
        out_h = as_i32(&raw[a++]);
    }
    for (int j = 0; ok && j < nc; ++j) {
      if (cty[j].kind == 'p') { /* one scalar (§1.4), never mixed (cq_standin.h: an address differs per run) */
        if (thunk || a >= nargs || d >= (int)ml) { /* stubgen.py never pairs a thunk with a pointer parameter */
          ok = 0;
          break;
        }
        if (mask[d] == '1') {
          int32_t hh = as_i32(&raw[a]);
          if (strcmp(ty[a].ty, "i32") || cqe__check(hh, sym) < 0) {
            ok = 0;
            break;
          }
          if (strcmp(cqe__w(hh), "i64") != 0) {
            cqe__violation("width_mismatch", hh, "%s: pointer argument %d of %s: rail %d is %s, an address rail is i64", sym,
                           j, fn, (int)hh, cqe__w(hh));
            ok = 0;
            break;
          }
          hs[nh++] = hh;
          known = known && cqe__known(hh);
        } else if (ty[a].kind != 'p') {
          ok = 0;
          break;
        }
        ++a;
        ++d;
        continue;
      }
      if (a >= nargs || d >= (int)ml) {
        ok = 0;
        break;
      }
      cqe_val v;
      int owned = 0;
      if (ab.p[ab.len - 1] != '[')
        sb_add(&ab, ",");
      if (mask[d] == '1') {
        int32_t hh = as_i32(&raw[a]);
        if (strcmp(ty[a].ty, "i32") || cqe__check(hh, sym) < 0) {
          ok = 0;
          break;
        }
        const cqe_val *rv = cqe__val(hh);
        if (rv->bits != cty[j].bits || rv->kind != (cty[j].kind == 'f' ? 'f' : 'i')) {
          cqe__violation("width_mismatch", hh, "%s: argument %d of %s is %s, rail %d is %s", sym, j, fn, cty[j].ty,
                         (int)hh, cqe__w(hh));
          ok = 0;
          break;
        }
        hs[nh++] = hh;
        known = known && cqe__known(hh);
        cqe__val_init(&v, rv->bits, rv->kind);
        cqe__val_copy_into(&v, rv);
        owned = 1;
        sb_addf(&ab, "{\"h\":%d,\"v\":\"", (int)hh);
        sb_hex(&ab, rv);
        sb_add(&ab, "\"}");
      } else {
        if (strcmp(ty[a].ty, cty[j].ty) != 0) {
          ok = 0;
          break;
        }
        v = raw[a];
        sb_add(&ab, "{\"lit\":\"");
        sb_hex(&ab, &v);
        sb_add(&ab, "\"}");
      }
      for (uint32_t w = 0; w < cqe__nwords(v.bits); ++w)
        h = cq_standin_mix(h, v.w[w]);
      if (thunk) {
        memset(cbuf[j], 0, sizeof cbuf[j]);
        store_val(cbuf[j], &cty[j], &v);
        cargs[j] = cbuf[j];
      }
      if (owned)
        cqe__val_free(&v);
      ++a;
      ++d;
    }
    /* K: a table clone's trailing i32 (rule 27). A rule 18 clone (no _t, 175's __cq_q_exp_1(i32)) has none. */
    if (ok && table) {
      if (a >= nargs || strcmp(ty[a].ty, "i32") != 0)
        ok = 0;
      else
        ++a;
    }
    if (ok && (a != nargs || d != (int)ml))
      ok = 0;
    sb_add(&ab, "]");
    if (!ok) {
      cqe__violation("malformed_call", -1, "%s: arguments '%s' do not follow rule 27 for C signature '%s' and mask %.*s",
                     sym, sig, csig, (int)ml, mask);
    } else if (crty.kind == 'v') {
      if (thunk && !unc)
        thunk(cargs, rbuf);
      sbuf b = {0};
      sb_addf(&b, "{\"ev\":\"standin\",\"sym\":\"%s\",\"args\":%s}", sym, ab.p);
      cqe_log(b.p);
      free(b.p);
    } else {
      char wt[16];
      if (crty.kind == 'p')
        snprintf(wt, sizeof wt, "i64"); /* cq_standin.h: a pointer result is null; a rail result is one 64-bit rail */
      else
        lty_wtok(&crty, wt, sizeof wt);
      cqe_val v;
      if (crty.kind == 'p') {
        cqe__val_init(&v, 64, 'i');
      } else if (thunk) { /* the host's fn (cq-aou6) */
        memset(rbuf, 0, sizeof rbuf);
        thunk(cargs, rbuf);
        load_val(&v, &crty, rbuf);
      } else {
        cqe__val_init(&v, crty.bits, crty.kind == 'f' ? 'f' : 'i');
        v.w[0] = h;
        cqe__val_mask(&v);
      }
      if (!unc) {
        int32_t o = cqe__new(wt, &v, known, 0);
        for (int i = 0; i < nh; ++i)
          cqe__add_dep(o, hs[i]);
        sbuf b = {0};
        sb_addf(&b, "{\"ev\":\"tmpl\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"w\":\"%s\",\"v\":\"", sym, (int)o, ab.p,
                wt);
        sb_hex(&b, cqe__val(o));
        sb_addf(&b, "\",\"known\":%s}", cqe__known(o) ? "true" : "false");
        cqe_log(b.p);
        free(b.p);
        cqe_val hv;
        cqe__val_init(&hv, 32, 'i');
        hv.w[0] = (uint32_t)o;
        store_val(ret, &rty, &hv);
        cqe__val_free(&hv);
      } else if (cqe__check(out_h, sym) == 0) {
        if (strcmp(cqe__w(out_h), wt) != 0)
          cqe__violation("width_mismatch", out_h, "%s: out rail %d is %s, %s returns %s", sym, (int)out_h,
                         cqe__w(out_h), fn, wt);
        cqe__val_xor(cqe__val(out_h), &v);
        cqe__carry(out_h, hs, nh);
        cqe__r6_unc(out_h, hs, nh);
        cqe__mark_written(out_h);
        sbuf b = {0};
        sb_addf(&b, "{\"ev\":\"unc\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"residue\":\"", sym, (int)out_h, ab.p);
        sb_hex(&b, cqe__val(out_h));
        sb_add(&b, "\"}");
        cqe_log(b.p);
        free(b.p);
        if (iv_quiet_unc) { /* the twin as the compute (cq_invert): the rail lives on, nothing to free */
          cqe__zero_rule(out_h, hs, nh);
        } else if (!cqe__val_iszero(cqe__val(out_h))) {
          char *hx = cqe__hexa(cqe__val(out_h));
          cqe__violation("unc_residue", out_h, "%s: out rail %d holds %s after its twin", sym, (int)out_h, hx);
          free(hx);
          cqe__setknown(out_h, 0);
        } else if (!cqe__zero_rule(out_h, hs, nh)) {
          cqe__violation("unc_after_nondiagonal", out_h,
                         "%s: rail %d or an operand took a non-diagonal gate after rail %d was computed", sym,
                         (int)out_h, (int)out_h);
        } else if (table) { /* §1.4: a table twin frees the results it zeroes */
          cqe__free_note(out_h, 1);
          cqe__free(out_h);
        }
      }
      cqe__val_free(&v);
    }
    free(ab.p);
  }
done:
  for (int i = 0; i < nargs; ++i)
    cqe__val_free(&raw[i]);
}

/* ---- cq_invert regions (CR rule 17, BACKEND_ABI 1.13; cq-4593) ------------------------------
 * cqrt_invert_begin opens a region; while one is open, a gate is RECORDED, not applied, and
 * cqrt_invert_end replays the region's gates reversed, each by its inverse, then the frees it recorded.
 *  - Gates: every template and _unc, every core XOR gate (not/and/or/xor_i1, copy, xorc), Ry and P
 *    (literal angle or angle rail), qram_swap, qram_load/_unc, tape_write, and a declared clone
 *    (rule 27 stand-in) and its twin. An Ry or P is inverted by negating its angle (an angle rail's value
 *    is negated for the call), a bus swap and every XOR gate are their own inverse.
 *  - A gate whose forward form makes a fresh rail (a template, qram_load, tape_write, a clone with a
 *    result) gets that rail at once, at |0> (allocations keep their place); the program holds its handle.
 *    The rail is PENDING until a replay first XORs into it: that replay is its compute, whichever of the
 *    pair it is (the reversed list runs a compute/uncompute pair the other way round), and the other one
 *    is its uncompute, with the residue check of an _unc.
 *  - Not gates, done at once: alloc, push/pop, qram_alloc, tape bookkeeping, abort flags.
 *    cqrt_free (a release) is performed after the reversed list.
 *  - A measurement, a bus store or an effect entry inside a region has no inverse: it first replays the
 *    gates recorded so far forward, as recorded (it needs them; every open region, outermost first) and is
 *    performed in place; only the gates recorded after it are reversed at the end.
 *  - Nested regions: an inner end appends its reversed list and its frees to the enclosing region's
 *    record. A region still open at the end of the shot is closed there (innermost first).
 * Reference: CQ_spec _tools/sample_check.py Eval.call models the same region. */

enum { IV_GATE, IV_XOR, IV_FREE };
typedef struct {
  int kind, inv, unc, standin;
  char *sym, *sig, *csig;
  void *thunk;
  int nargs;
  uint8_t (*buf)[16];
  int32_t out; /* IV_XOR: the rail the gate XORs into */
} iv_op;
typedef struct {
  iv_op *v;
  size_t n, cap;
} iv_list;
static iv_list *iv_open;
static size_t iv_nopen, iv_capopen;
static int iv_replaying;
static int32_t *iv_pend;
static size_t iv_npend, iv_cappend;

void cqe__prealloc(int32_t h);   /* core.c */
void cqe__recreated(int32_t h);  /* core.c */

static char *iv_dup(const char *s) {
  if (!s)
    return NULL;
  char *d = strdup(s);
  if (!d)
    abort();
  return d;
}

static void iv_append(iv_list *l, const iv_op *op) {
  if (l->n == l->cap) {
    l->cap = l->cap ? 2 * l->cap : 32;
    l->v = realloc(l->v, l->cap * sizeof *l->v);
    if (!l->v)
      abort();
  }
  l->v[l->n++] = *op;
}

static void iv_pend_add(int32_t h) {
  if (iv_npend == iv_cappend) {
    iv_cappend = iv_cappend ? 2 * iv_cappend : 32;
    iv_pend = realloc(iv_pend, iv_cappend * sizeof *iv_pend);
    if (!iv_pend)
      abort();
  }
  iv_pend[iv_npend++] = h;
}

static int iv_pend_take(int32_t h) {
  for (size_t i = 0; i < iv_npend; ++i)
    if (iv_pend[i] == h) {
      iv_pend[i] = iv_pend[--iv_npend];
      return 1;
    }
  return 0;
}

static int ends_with(const char *s, const char *suf) {
  size_t n = strlen(s), m = strlen(suf);
  return n >= m && !strcmp(s + n - m, suf);
}

/* A fresh |0> rail of width w for a recorded gate's result; its handle goes to the program. */
static int32_t iv_reserve(const char *w, const lty *rty, void *ret) {
  int32_t h = cqe__new(w, NULL, 1, 0);
  iv_pend_add(h);
  cqe_val r;
  cqe__val_init(&r, 32, 'i');
  r.w[0] = (uint32_t)h;
  store_val(ret, rty, &r);
  cqe__val_free(&r);
  return h;
}

static void iv_run(const iv_op *op);

/* The clone name read right to left (CR §1.4): its suffix words end in _t. */
static int clone_is_table(const char *sym) {
  char b[256];
  snprintf(b, sizeof b, "%s", sym);
  for (;;) {
    if (ends_with(b, "_unc"))
      b[strlen(b) - 4] = 0;
    else if (ends_with(b, "_pure"))
      b[strlen(b) - 5] = 0;
    else if (ends_with(b, "_ctl"))
      b[strlen(b) - 4] = 0;
    else
      return ends_with(b, "_t");
  }
}

/* Replay every open region's record forward (a measurement needs the gates before it). */
static void iv_flush_forward(void) {
  for (size_t d = 0; d < iv_nopen; ++d) {
    iv_list *l = &iv_open[d];
    for (size_t i = 0; i < l->n; ++i)
      iv_run(&l->v[i]);
    l->n = 0;
  }
}

static void iv_close(void) {
  iv_list l = iv_open[--iv_nopen];
  iv_list out = {0};
  for (size_t i = l.n; i-- > 0;)
    if (l.v[i].kind != IV_FREE) {
      iv_op o = l.v[i];
      o.inv = !o.inv;
      iv_append(&out, &o);
    }
  for (size_t i = 0; i < l.n; ++i)
    if (l.v[i].kind == IV_FREE)
      iv_append(&out, &l.v[i]);
  free(l.v);
  if (iv_nopen) {
    for (size_t i = 0; i < out.n; ++i)
      iv_append(&iv_open[iv_nopen - 1], &out.v[i]);
  } else {
    for (size_t i = 0; i < out.n; ++i)
      iv_run(&out.v[i]);
  }
  free(out.v);
}

void cqe__invert_close_all(void) {
  while (iv_nopen)
    iv_close();
}

static int iv_intercept(const char *sym, const char *sig, const char *csig, int32_t nargs, void **argv, void *ret,
                        void *thunk) {
  if (cqe__rp_window && !csig && !strncmp(sym, "cqrt_invert_", 12)) /* cq-kcn5i: never in a replayed clone */
    cqe__rp_dirty = 1;
  if (!csig && !strcmp(sym, "cqrt_invert_begin")) {
    if (nargs != 0)
      cqe__violation("malformed_call", -1, "%s: expected ()", sym);
    if (iv_nopen == iv_capopen) {
      iv_capopen = iv_capopen ? 2 * iv_capopen : 8;
      iv_open = realloc(iv_open, iv_capopen * sizeof *iv_open);
      if (!iv_open)
        abort();
    }
    memset(&iv_open[iv_nopen++], 0, sizeof *iv_open);
    return 1;
  }
  if (!csig && !strcmp(sym, "cqrt_invert_end")) {
    if (nargs != 0)
      cqe__violation("malformed_call", -1, "%s: expected ()", sym);
    if (!iv_nopen)
      cqe__violation("invert_unbalanced", -1, "%s: no cq_invert region is open", sym);
    else
      iv_close();
    return 1;
  }
  if (!iv_nopen || iv_replaying)
    return 0;
  lty rty, ty[64];
  int n = nargs;
  if (nargs < 0 || nargs > 64 || parse_sig(sig, &rty, ty, &n))
    return 0; /* the ordinary path reports it */
  iv_op op = {0};
  op.kind = IV_GATE;
  if (csig) {
    op.standin = 1;
    op.kind = IV_XOR;
    op.unc = ends_with(sym, "_unc");
    if (op.unc) {
      if (nargs < 1 || strcmp(ty[0].ty, "i32"))
        return 0;
      memcpy(&op.out, argv[0], 4);
    } else {
      const char *b1 = strchr(csig, '|'), *b2 = b1 ? strchr(b1 + 1, '|') : NULL;
      lty crty;
      char wt[16];
      if (!b2 || parse_lty(b1 + 1, (size_t)(b2 - b1 - 1), &crty) || crty.kind == 'v' ||
          !lty_wtok(&crty, wt, sizeof wt) || strcmp(rty.ty, "i32"))
        return 0; /* a void clone has no effect (rule 27); anything else the ordinary path reports */
      op.out = iv_reserve(wt, &rty, ret);
    }
  } else if (!strncmp(sym, "cq_template_", 12)) {
    cqe_tname t;
    if (cqe_parse_template(sym, &t))
      return 0;
    op.kind = IV_XOR;
    op.unc = t.unc;
    if (t.unc) {
      if (nargs < 1 || strcmp(ty[0].ty, "i32"))
        return 0;
      memcpy(&op.out, argv[0], 4);
    } else {
      if (strcmp(rty.ty, "i32"))
        return 0;
      op.out = iv_reserve(result_w(&t), &rty, ret);
    }
  } else if (!strncmp(sym, "cqrt_", 5)) {
    const char *s = sym + 5;
    char cls[64];
    cqe_tname t;
    if (!strcmp(s, "free")) {
      op.kind = IV_FREE;
    } else if (!strncmp(s, "measure_", 8)) {
      int32_t h = 0;
      if (nargs == 1 && !strcmp(ty[0].ty, "i32"))
        memcpy(&h, argv[0], 4);
      if (!(cqe__exists(h) && cqe__measured(h)))
        iv_flush_forward(); /* a re-read of a measured rail is no measurement event (ABI 1.3) */
      return 0;
    } else if (core_gate(NULL, s, cls, sizeof cls)) {
      if (!strcmp(cls, "core:alloc") || !strcmp(cls, "core:push") || !strcmp(cls, "core:pop"))
        return 0;
    } else if (parse_family(s, &t) == 0) {
      if (!strcmp(t.op, "qram_store") || !strcmp(t.op, "tape_effect")) {
        iv_flush_forward(); /* ABI 1.13: performed at its call, the store's slot kept */
        return 0;
      } else if (!strcmp(t.op, "qram_swap")) {
        op.kind = IV_GATE;
      } else if (!strcmp(t.op, "qram_load")) {
        op.kind = IV_XOR;
        op.unc = t.unc;
        if (t.unc) {
          if (nargs < 1 || strcmp(ty[0].ty, "i32"))
            return 0;
          memcpy(&op.out, argv[0], 4);
        } else {
          if (strcmp(rty.ty, "i32") || !cqe__wtok_bits(t.w, NULL))
            return 0;
          op.out = iv_reserve(t.w, &rty, ret);
        }
      } else if (!strcmp(t.op, "tape_write") && strcmp(t.shape, "l")) {
        int32_t src;
        if (nargs < 2 || strcmp(rty.ty, "i32") || strcmp(ty[nargs - 1].ty, "i32"))
          return 0;
        memcpy(&src, argv[nargs - 1], 4);
        if (!cqe__exists(src))
          return 0;
        char w[8];
        snprintf(w, sizeof w, "%s", cqe__w(src));
        op.kind = IV_XOR;
        op.out = iv_reserve(w, &rty, ret);
        cqe__setrole(op.out, 2); /* a tape rail (C1 roles) */
      } else {
        return 0; /* bookkeeping: qram_alloc, tape_alloc/fmt, literal writes, abort */
      }
    } else {
      return 0;
    }
  } else {
    return 0;
  }
  op.sym = iv_dup(sym);
  op.sig = iv_dup(sig);
  op.csig = iv_dup(csig);
  op.thunk = thunk;
  op.nargs = nargs;
  op.buf = calloc((size_t)(nargs ? nargs : 1), sizeof *op.buf);
  if (!op.buf)
    abort();
  for (int i = 0; i < nargs; ++i)
    memcpy(op.buf[i], argv[i], ty[i].bytes);
  iv_append(&iv_open[iv_nopen - 1], &op);
  return 1;
}

static void iv_call(const iv_op *op, const char *sym, const char *sig, void **argv, int nargs, void *ret) {
  if (op->standin)
    standin(sym, sig, op->csig, nargs, argv, ret, (standin_thunk)op->thunk);
  else
    cqe_dispatch(sym, sig, nargs, argv, ret);
  cqe__prealloc(0);
}

static void iv_run(const iv_op *op) {
  ++iv_replaying;
  _Alignas(16) uint8_t buf[65][16];
  _Alignas(16) uint8_t rbuf[16];
  void *argv[65];
  int nargs = op->nargs;
  memcpy(buf, op->buf, (size_t)nargs * sizeof *buf);
  for (int i = 0; i < 65; ++i)
    argv[i] = buf[i];
  memset(rbuf, 0, sizeof rbuf);
  char sym[256], sig[1100];
  snprintf(sym, sizeof sym, "%s", op->sym);
  snprintf(sig, sizeof sig, "%s", op->sig);
  if (op->kind == IV_FREE) {
    iv_call(op, sym, sig, argv, nargs, rbuf);
  } else if (op->kind == IV_GATE) {
    int qang = strstr(sym, "qangle") != NULL;
    int rot = !strncmp(sym, "cqrt_ry_", 8) || !strncmp(sym, "cqrt_rz_", 8);
    int32_t a = 0;
    if (op->inv && rot && nargs > 0) {
      if (qang) {
        memcpy(&a, buf[nargs - 1], 4);
        if (cqe__exists(a))
          cqe__val(a)->w[0] ^= 1ULL << 63; /* the angle rail (f64) negated for the call */
        else
          a = 0;
      } else {
        buf[nargs - 1][7] ^= 0x80; /* the double literal negated */
      }
    }
    iv_call(op, sym, sig, argv, nargs, rbuf);
    if (a)
      cqe__val(a)->w[0] ^= 1ULL << 63;
  } else {
    int pend = iv_pend_take(op->out);
    if (pend)
      cqe__recreated(op->out); /* computed now: later gates on its sources come after it (zero rule) */
    const char *params = strchr(op->sig, '|');
    params = params ? params + 1 : "";
    if (op->standin || strstr(sym, "cqrt_tape_write")) {
      if (op->unc) {
        iv_quiet_unc = pend;
        iv_call(op, sym, sig, argv, nargs, rbuf);
        iv_quiet_unc = 0;
      } else {
        cqe__prealloc(op->out);
        iv_call(op, sym, sig, argv, nargs, rbuf);
        if (!pend && cqe__exists(op->out) && !cqe__val_iszero(cqe__val(op->out))) {
          char *hx = cqe__hexa(cqe__val(op->out));
          cqe__violation("unc_residue", op->out, "%s: out rail %d holds %s after its replayed uncompute (cq_invert)",
                         sym, (int)op->out, hx);
          free(hx);
          cqe__setknown(op->out, 0);
        } else if (!pend && op->standin && clone_is_table(sym) && cqe__exists(op->out)) {
          /* a table clone's forward form replayed as its uncompute: the twin's free (§1.4) */
          cqe__free_note(op->out, 1);
          cqe__free(op->out);
        }
      }
    } else if (!op->unc) {
      if (pend) {
        cqe__prealloc(op->out);
        iv_call(op, sym, sig, argv, nargs, rbuf);
      } else { /* the uncompute: the _unc form, (out, args...) */
        strncat(sym, "_unc", sizeof sym - strlen(sym) - 1);
        snprintf(sig, sizeof sig, "void|i32%s%s", *params ? "," : "", params);
        memmove(buf[1], buf[0], (size_t)nargs * sizeof *buf);
        memcpy(buf[0], &op->out, 4);
        iv_call(op, sym, sig, argv, nargs + 1, rbuf);
      }
    } else if (!pend) {
      iv_call(op, sym, sig, argv, nargs, rbuf);
    } else { /* a template's or qram_load's _unc as the compute: the forward form into the |0> rail */
      sym[strlen(sym) - 4] = 0;
      const char *rest = strchr(params, ',');
      snprintf(sig, sizeof sig, "i32|%s", rest ? rest + 1 : "");
      memmove(buf[0], buf[1], (size_t)(nargs - 1) * sizeof *buf);
      cqe__prealloc(op->out);
      iv_call(op, sym, sig, argv, nargs - 1, rbuf);
    }
  }
  --iv_replaying;
}

/* Classification for tests and tools: "core:<gate>", "template:<op>", "family:<op>"; -1 unknown. */
int cqe__classify(const char *sym, char *cls, size_t ncls) {
  cqe_tname t;
  if (!strncmp(sym, "cq_template_", 12)) {
    if (cqe_parse_template(sym, &t))
      return -1;
    snprintf(cls, ncls, "template:%s", t.op);
    return 0;
  }
  if (!strncmp(sym, "cqrt_", 5)) {
    if (!strcmp(sym, "cqrt_invert_begin") || !strcmp(sym, "cqrt_invert_end")) {
      snprintf(cls, ncls, "core:%s", sym + 5); /* rule 17 (BACKEND_ABI 1.13): the cq_invert region markers */
      return 0;
    }
    if (core_gate(NULL, sym + 5, cls, ncls))
      return 0;
    if (parse_family(sym + 5, &t) == 0) {
      snprintf(cls, ncls, "family:%s", t.op);
      return 0;
    }
  }
  return -1;
}

/* cq-kcn5i (rt_replay.c): no cq_invert region is open or replaying, so a gate is applied where it is called. */
int cqe__rp_dispatch_idle(void) { return iv_nopen == 0 && iv_replaying == 0; }
