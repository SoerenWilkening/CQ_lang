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
 *   cqrt_<other>      the family path: qram_alloc, qram_realloc, qram_store, qram_load, qram_free,
 *                     tape_alloc, tape_fmt, tape_effect, tape_write, tape_write_str, abort. tname.op is
 *                     that stem; tname.w the width token ("" if none); tname.shape "hl" for _hl and "l"
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
 *                        the _rm/_rmq mode, qrom's table/n/stride/idx), each resolved: a handle to a
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
 * dirty_free (free of a rail not in a known basis state), free_forbidden (free of a measured, tape or
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
void cqe__setrole(int32_t h, int role);
void cqe__setfenv(int32_t h, int bits); /* core.c (cq-tt2j) */
void cqe__mark_written(int32_t h);
void cqe__mark_nd(int32_t h);
void cqe__mark_measured(int32_t h);
void cqe__add_dep(int32_t h, int32_t src);
int cqe__free_note(int32_t h, int known); /* core.c (cq-8m6v) */
void cqe__free(int32_t h);

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
}

/* Try every handler of op in registration order. 0 computed, -1 failed (violation written). */
static int run_handlers(const char *sym, const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  int seen = 0;
  for (size_t i = 0; i < nregs; ++i) {
    if (strcmp(regs[i].op, t->op) != 0)
      continue;
    seen = 1;
    memset(out->w, 0, out->nw * sizeof *out->w);
    cqe_val pre = *out;
    int r = regs[i].fn(t, args, nargs, out);
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
      cqe__val_mask(out);
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
    "sitofp", "uitofp", "fptosi", "fptoui", "bitcast", "fma", "fshl", "fshr", "abs", "ctlz", "cttz", "ctpop", "bswap",
    "smax", "smin", "umax", "umin", "uadd_sat", "usub_sat", "sadd_sat", "ssub_sat", "uadd_overflow", "sadd_overflow", "usub_overflow",
    "ssub_overflow", "umul_overflow", "smul_overflow", "fabs", "copysign", "fmax", "fmin", "floor", "ceil", "rint",
    "round", "sqrt", "is_fpclass", "qrom_load", NULL};
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
  if (i < nt && strcmp(tok[i], "s") == 0 && strcmp(out->op, "qrom_load") == 0) {
    out->strided = 1;
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
  if (!strcmp(t->op, "qrom_load")) {
    if (nf != (t->strided ? 4 : 3) || t->shape[0] || t->rm || t->exc)
      return -1;
    for (int i = 0; i < nf; ++i)
      mask[i] = 'l';
    mask[nf - 1] = 'h';
    mask[nf] = 0;
    return 0;
  }
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
  return 0;
}

static void load_val(cqe_val *v, const lty *t, const void *mem) {
  cqe__val_init(v, t->bits, t->kind == 'f' ? 'f' : 'i');
  memcpy(v->w, mem, t->bytes);
  cqe__val_mask(v);
}

static void store_val(void *mem, const lty *t, const cqe_val *v) {
  if (t->kind == 'v' || !mem)
    return;
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
static int zero_rule(int32_t d, const int32_t *src, int ns) {
  if (cqe__val_iszero(cqe__val(d))) {
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

/* ---- core gates -------------------------------------------------------------------------- */

static int32_t *stack_;
static size_t nstack, capstack;

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
    if (types[i] == 'h' && strcmp(c->ty[i].ty, "i32") != 0) {
      cqe__violation("malformed_call", -1, "%s: argument %d is %s, expected an i32 handle", c->sym, i, c->ty[i].ty);
      return 0;
    }
    if (types[i] == 'd' && strcmp(c->ty[i].ty, "double") != 0) {
      cqe__violation("malformed_call", -1, "%s: argument %d is %s, expected double", c->sym, i, c->ty[i].ty);
      return 0;
    }
  }
  return 1;
}

/* Check a handle operand is live and (if w) of width w. 1 usable. */
static int operand(const call_t *c, int32_t h, const char *w) {
  int r = cqe__check(h, c->sym);
  if (r < 0)
    return 0;
  if (w && strcmp(cqe__w(h), w) != 0) {
    cqe__violation("width_mismatch", h, "%s: rail %d is %s, expected %s", c->sym, (int)h, cqe__w(h), w);
    return 0;
  }
  return 1;
}

static int distinct(const call_t *c, int32_t target, const int32_t *others, int n) {
  for (int i = 0; i < n; ++i)
    if (others[i] == target) {
      cqe__violation("target_aliases_operand", target, "%s: in-place target %d is also operand", c->sym, (int)target);
      return 0;
    }
  return 1;
}

static void log_gate(const call_t *c, int32_t h, const int32_t *srcs, int ns) {
  sbuf b = {0};
  sb_addf(&b, "{\"ev\":\"gate\",\"sym\":\"%s\",\"h\":%d,\"v\":\"", c->sym, (int)h);
  sb_hex(&b, cqe__val(h));
  sb_addf(&b, "\",\"known\":%s,\"args\":[", cqe__known(h) ? "true" : "false");
  for (int i = 0; i < ns; ++i)
    sb_addf(&b, "%s%d", i ? "," : "", (int)srcs[i]);
  sb_add(&b, "]}");
  cqe_log(b.p);
  free(b.p);
}

static void log_rot(const char *ev, const call_t *c, int32_t h, int32_t ctl, const char *angle_fields) {
  sbuf b = {0};
  sb_addf(&b, "{\"ev\":\"%s\",\"h\":%d,%s,\"ctl\":[", ev, (int)h, angle_fields);
  if (ctl > 0)
    sb_addf(&b, "%d", (int)ctl);
  sb_add(&b, "],\"ctlv\":[");
  if (ctl > 0)
    sb_addf(&b, "%d", (int)(cqe__val(ctl)->w[0] & 1));
  sb_addf(&b, "],\"w\":\"%s\",\"v\":\"", cqe__w(h));
  sb_hex(&b, cqe__val(h));
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

static void gate_alloc(call_t *c, const char *w) {
  if (c->nargs != 1 || strcmp(c->rty->ty, "i32") != 0) {
    cqe__violation("malformed_call", -1, "%s: expected (lit) -> i32", c->sym);
    return;
  }
  int32_t h = cqe__new(w, &c->raw[0], 1, 1);
  char *hx = cqe__hexa(cqe__val(h));
  cqe__logf("{\"ev\":\"alloc\",\"h\":%d,\"w\":\"%s\",\"v\":\"%s\",\"known\":true}", (int)h, w, hx);
  free(hx);
  cqe_val r;
  cqe__val_init(&r, 32, 'i');
  r.w[0] = (uint32_t)h;
  store_val(c->ret, c->rty, &r);
  cqe__val_free(&r);
}

static void gate_free(call_t *c) {
  if (!want_args(c, 1, "h"))
    return;
  int32_t h = as_i32(&c->raw[0]);
  if (cqe__check(h, c->sym) != 0)
    return;
  char *hx = cqe__hexa(cqe__val(h));
  int known = cqe__known(h);
  if (cqe__free_note(h, known))
    cqe__logf("{\"ev\":\"free\",\"h\":%d,\"v\":\"%s\",\"known\":%s,\"w\":\"%s\"}", (int)h, hx, known ? "true" : "false",
            cqe__w(h));
  free(hx);
  if (cqe__measured(h) || cqe__role(h) == 1 || cqe__role(h) == 2)
    cqe__violation("free_forbidden", h, "%s: rail %d is a %s rail", c->sym, (int)h,
                   cqe__measured(h) ? "measured" : cqe__role(h) == 1 ? "abort" : "tape");
  if (!known)
    cqe__violation("dirty_free", h, "%s: rail %d is not in a known basis state", c->sym, (int)h);
  cqe__free(h);
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
    char *hx = cqe__hexa(cqe__val(h));
    cqe__logf("{\"ev\":\"measure\",\"h\":%d,\"v\":\"%s\",\"w\":\"%s\"}", (int)h, hx, w);
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

/* A firing Ry on rail h with angle bits `angle`: take the schedule's reach (header). */
static void theta_substitute(int32_t h, uint64_t angle) {
  if (!theta_loaded)
    theta_load();
  if (!theta_sched)
    return;
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
    return;
  }
  cqe__logf("{\"ev\":\"theta_unmatched\",\"h\":%d,\"w\":\"%s\",\"angle\":\"0x%llx\"}", (int)h, w,
            (unsigned long long)angle);
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
  int finite;
  if (q) {
    int32_t a = as_i32(&c->raw[n - 1]);
    if (!operand(c, a, "f64"))
      return;
    if (!distinct(c, h, &a, 1))
      return;
    double av = as_f64(cqe__val(a));
    finite = isfinite(av);
    if (!ctl || (cqe__val(cf)->w[0] & 1)) {
      uint64_t ab;
      memcpy(&ab, &av, 8);
      theta_substitute(h, ab);
    }
    char *hx = cqe__hexa(cqe__val(a));
    snprintf(fields, sizeof fields, "\"a\":%d,\"aval\":\"%s\"", (int)a, hx);
    free(hx);
    log_rot("ry_qangle", c, h, cf, fields);
    cqe__add_dep(h, a);
  } else {
    double th = as_f64(&c->raw[n - 1]);
    finite = isfinite(th);
    if (!ctl || (cqe__val(cf)->w[0] & 1))
      theta_substitute(h, c->raw[n - 1].w[0]);
    snprintf(fields, sizeof fields, "\"theta\":\"0x%llx\"", (unsigned long long)c->raw[n - 1].w[0]);
    log_rot("ry", c, h, cf, fields);
  }
  if (ctl)
    cqe__add_dep(h, cf);
  /* A non-finite literal angle is the identity on every branch; an angle rail may be finite on
   * another branch, so it always counts as a non-diagonal gate. */
  if (q || finite) {
    cqe__mark_nd(h);
    if (!(ctl && cqe__known(cf) && (cqe__val(cf)->w[0] & 1) == 0))
      cqe__setknown(h, 0);
  }
}

static void gate_rz_i1(call_t *c) {
  if (!want_args(c, 2, "hd"))
    return;
  int32_t f = as_i32(&c->raw[0]);
  if (!operand(c, f, "i1"))
    return;
  cqe__logf("{\"ev\":\"phase\",\"f\":%d,\"fv\":%d,\"theta\":\"0x%llx\"}", (int)f, (int)(cqe__val(f)->w[0] & 1),
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
  sb_addf(&b, "{\"ev\":\"phase_qangle\",\"a\":%d,\"aval\":\"", (int)a);
  sb_hex(&b, cqe__val(a));
  sb_add(&b, "\",\"ctl\":[");
  if (ctl)
    sb_addf(&b, "%d", (int)cf);
  sb_add(&b, "],\"ctlv\":[");
  if (ctl)
    sb_addf(&b, "%d", (int)(cqe__val(cf)->w[0] & 1));
  sb_add(&b, "]}");
  cqe_log(b.p);
  free(b.p);
}

/* not/and/or/xor_i1 */
static void gate_logic(call_t *c, const char *op) {
  int n = !strcmp(op, "not") ? 1 : !strcmp(op, "xor") ? 2 : 3;
  if (!want_args(c, n, n == 1 ? "h" : n == 2 ? "hh" : "hhh"))
    return;
  int32_t hs[3];
  for (int i = 0; i < n; ++i) {
    hs[i] = as_i32(&c->raw[i]);
    if (!operand(c, hs[i], "i1"))
      return;
  }
  int32_t t = hs[n - 1];
  if (!distinct(c, t, hs, n - 1))
    return;
  uint64_t a = n > 1 ? cqe__val(hs[0])->w[0] & 1 : 0, b = n > 2 ? cqe__val(hs[1])->w[0] & 1 : 0, d;
  if (n == 1)
    d = 1;
  else if (n == 2)
    d = a;
  else
    d = !strcmp(op, "and") ? (a & b) : (a | b);
  cqe__val(t)->w[0] ^= d;
  cqe__mark_written(t);
  for (int i = 0; i < n - 1; ++i)
    cqe__add_dep(t, hs[i]);
  zero_rule(t, hs, n - 1);   /* not_i1 too: a flag an X returns to 0 is known again (cq-aypc) */
  log_gate(c, t, hs, n - 1);
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
  if (ctl && !operand(c, cf, "i1"))
    return;
  int32_t target, srcs[2];
  int ns = 0;
  const cqe_val *delta;
  if (is_copy) {
    int32_t d = as_i32(&c->raw[n - 1]);
    if (!operand(c, a, w) || !operand(c, d, w))
      return;
    target = d;
    srcs[ns++] = a;
    delta = cqe__val(a);
  } else {
    if (!operand(c, a, w))
      return;
    target = a;
    delta = &c->raw[n - 1];
  }
  if (ctl)
    srcs[ns++] = cf;
  if (!distinct(c, target, srcs, ns))
    return;
  int fire = !ctl || (cqe__val(cf)->w[0] & 1);
  if (ctl && cqe__known(cf) && !fire) {
    log_gate(c, target, srcs, ns); /* known control 0: nothing happens on any branch */
    return;
  }
  if (fire)
    cqe__val_xor(cqe__val(target), delta);
  cqe__mark_written(target);
  for (int i = 0; i < ns; ++i)
    cqe__add_dep(target, srcs[i]);
  if (is_copy || ctl)
    zero_rule(target, srcs, ns);
  log_gate(c, target, srcs, ns);
}

static void gate_push(call_t *c) {
  if (c->nargs != 1 || strcmp(c->ty[0].ty, "i32") != 0) {
    cqe__violation("malformed_call", -1, "%s: expected (i32)", c->sym);
    return;
  }
  if (nstack == capstack) {
    capstack = capstack ? 2 * capstack : 256;
    stack_ = realloc(stack_, capstack * sizeof *stack_);
    if (!stack_)
      abort();
  }
  stack_[nstack++] = as_i32(&c->raw[0]);
  cqe__logf("{\"ev\":\"push\",\"word\":%d}", (int)as_i32(&c->raw[0]));
}

static void gate_pop(call_t *c) {
  int32_t w = 0;
  if (c->nargs != 0 || strcmp(c->rty->ty, "i32") != 0)
    cqe__violation("malformed_call", -1, "%s: expected () -> i32", c->sym);
  if (nstack == 0)
    cqe__violation("pop_empty", -1, "%s: the word stack is empty", c->sym);
  else
    w = stack_[--nstack];
  cqe__logf("{\"ev\":\"pop\",\"word\":%d}", (int)w);
  cqe_val r;
  cqe__val_init(&r, 32, 'i');
  r.w[0] = (uint32_t)w;
  store_val(c->ret, c->rty, &r);
  cqe__val_free(&r);
}

/* Route a cqrt_* core gate. 1 handled, 0 not a core gate. With c == NULL only classifies. */
static int core_gate(call_t *c, const char *s, char *cls, size_t ncls) {
  char w[8];
  const char *r;
  int q, ctl, unc;
#define CLS(x)                                                                                     \
  do {                                                                                             \
    if (cls)                                                                                       \
      snprintf(cls, ncls, "core:%s", x);                                                           \
  } while (0)
  if (!strcmp(s, "free")) {
    CLS("free");
    if (c)
      gate_free(c);
    return 1;
  }
  if (!strcmp(s, "push")) {
    CLS("push");
    if (c)
      gate_push(c);
    return 1;
  }
  if (!strcmp(s, "pop")) {
    CLS("pop");
    if (c)
      gate_pop(c);
    return 1;
  }
  if (!strncmp(s, "alloc_", 6) && (r = take_w(s + 6, w, sizeof w)) && !*r) {
    CLS("alloc");
    if (c)
      gate_alloc(c, w);
    return 1;
  }
  if (!strncmp(s, "measure_", 8) && (r = take_w(s + 8, w, sizeof w)) && !*r) {
    CLS("measure");
    if (c)
      gate_measure(c, w);
    return 1;
  }
  if (!strncmp(s, "ry_", 3) && (r = take_w(s + 3, w, sizeof w)) && !suffixes(r, 1, 1, 0, &q, &ctl, &unc)) {
    CLS(q ? "ry_qangle" : "ry");
    if (c)
      gate_ry(c, w, q, ctl);
    return 1;
  }
  if (!strcmp(s, "rz_i1")) {
    CLS("rz_i1");
    if (c)
      gate_rz_i1(c);
    return 1;
  }
  if (!strncmp(s, "rz_qangle", 9) && !suffixes(s + 9, 0, 1, 0, &q, &ctl, &unc)) {
    CLS("rz_qangle");
    if (c)
      gate_rz_qangle(c, ctl);
    return 1;
  }
  static const char *const logic[] = {"not", "and", "or", "xor"};
  for (int i = 0; i < 4; ++i) {
    size_t n = strlen(logic[i]);
    if (!strncmp(s, logic[i], n) && !strncmp(s + n, "_i1", 3) && !suffixes(s + n + 3, 0, 0, 1, &q, &ctl, &unc)) {
      CLS(logic[i]);
      if (c)
        gate_logic(c, logic[i]);
      return 1;
    }
  }
  int is_copy = !strncmp(s, "copy_", 5), is_xorc = !strncmp(s, "xorc_", 5);
  if ((is_copy || is_xorc) && (r = take_w(s + 5, w, sizeof w)) && !suffixes(r, 0, 1, 1, &q, &ctl, &unc)) {
    CLS(is_copy ? "copy" : "xorc");
    if (c)
      gate_copy_xorc(c, w, is_copy, ctl);
    return 1;
  }
#undef CLS
  return 0;
}

/* ---- family path ------------------------------------------------------------------------- */

static const char *const fam_stems[] = {"qram_alloc", "qram_realloc", "qram_store", "qram_load", "qram_free",
                                        "tape_alloc", "tape_fmt",     "tape_effect", "tape_write_str",
                                        "tape_write", "abort",        NULL};

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

static void family_call(call_t *c, const cqe_tname *t) {
  cqe_val out;
  cqe__val_init(&out, c->rty->kind == 'v' ? 0 : c->rty->bits, c->rty->kind == 'f' ? 'f' : 'i');
  if (out.nw == 0) {
    out.nw = 1;
  }
  if (!strcmp(t->op, "abort") && c->nargs >= 1 && cqe__exists(as_i32(&c->raw[0])))
    cqe__setrole(as_i32(&c->raw[0]), 1);
  /* rails the family creates during this call get the family's exit role */
  int32_t before = (int32_t)cqe__nrails_peek();
  int r = run_handlers(c->sym, t, c->raw, c->nargs, &out);
  int32_t after = (int32_t)cqe__nrails_peek() + 1;
  int role = !strncmp(t->op, "tape_write", 10) ? 2 : (!strcmp(t->op, "qram_alloc") || !strcmp(t->op, "qram_realloc") ||
                                                      !strcmp(t->op, "qram_store"))
                                                         ? 3
                                                         : 0;
  if (role)
    for (int32_t h = before + 1; h < after; ++h)
      cqe__setrole(h, role);
  if (r == 0)
    store_val(c->ret, c->rty, &out);
  cqe__val_free(&out);
}

/* ---- template path ----------------------------------------------------------------------- */

static void template_call(call_t *c, const char *sym) {
  cqe_tname t;
  int is_i32_ret = !strcmp(c->rty->ty, "i32");
  if (cqe_parse_template(sym, &t) != 0) {
    cqe__violation("bad_template", -1, "%s: not a template name (CR §1.2)", sym);
    if (is_i32_ret) {
      cqe_val z;
      cqe__val_init(&z, 32, 'i');
      z.w[0] = (uint32_t)cqe__new("i1", NULL, 0, 0);
      store_val(c->ret, c->rty, &z);
      cqe__val_free(&z);
    }
    return;
  }
  int off = t.unc ? 1 : 0, nf = c->nargs - off;
  char mask[66];
  const char *rw = result_w(&t);
  char rkind = 0;
  uint32_t rbits = cqe__wtok_bits(rw, &rkind);
  int ok = cqe__template_layout(&t, nf, mask) == 0;
  if (!ok)
    cqe__violation("malformed_call", -1, "%s: %d forward arguments do not fit the name", sym, nf);
  if (t.unc && (c->nargs < 1 || strcmp(c->ty[0].ty, "i32") || c->rty->kind != 'v')) {
    cqe__violation("malformed_call", -1, "%s: an _unc takes (i32 out, args...) and returns void", sym);
    ok = 0;
  }
  if (!t.unc && !is_i32_ret) {
    cqe__violation("malformed_call", -1, "%s: a forward template returns an i32 handle", sym);
    ok = 0;
  }
  for (int i = 0; ok && i < nf; ++i)
    if (mask[i] == 'h' && strcmp(c->ty[off + i].ty, "i32") != 0) {
      cqe__violation("malformed_call", -1, "%s: handle argument %d is %s", sym, i, c->ty[off + i].ty);
      ok = 0;
    }
  /* resolve operands */
  cqe_val *args = calloc((size_t)(nf > 0 ? nf : 1), sizeof *args);
  char *owned = calloc((size_t)(nf > 0 ? nf : 1), 1);
  int32_t hs[66];
  int nh = 0, known = 1;
  sbuf ab = {0};
  sb_add(&ab, "[");
  for (int i = 0; ok && i < nf; ++i) {
    const cqe_val *raw = &c->raw[off + i];
    if (i)
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
      cqe__val_init(&args[i], rv->bits, rv->kind);
      cqe__val_copy_into(&args[i], rv);
      owned[i] = 1;
      sb_addf(&ab, "{\"h\":%d,\"v\":\"", (int)h);
      sb_hex(&ab, cqe__val(h));
      sb_add(&ab, "\"}");
    } else {
      args[i] = *raw;
      sb_add(&ab, "{\"lit\":\"");
      sb_hex(&ab, raw);
      sb_add(&ab, "\"}");
    }
  }
  sb_add(&ab, "]");
  cqe_val out;
  cqe__val_init(&out, rbits ? rbits : 1, rkind ? rkind : 'i');
  int r = ok ? run_handlers(sym, &t, args, nf, &out) : -1;
  if (r == 0 && out.bits != (rbits ? rbits : 1)) {
    cqe__violation("result_width", -1, "%s: handler produced %u bits, the name implies %u", sym, out.bits, rbits);
    r = -1;
  }
  if (r != 0)
    memset(out.w, 0, out.nw * sizeof *out.w);
  out.bits = rbits ? rbits : 1;
  /* rule 23 (cq-tt2j): an _rmq template's last operand is the mode rail; an _exc result is flags */
  if (ok && t.rm == 2 && nf > 0 && mask[nf - 1] == 'h')
    cqe__setfenv(as_i32(&c->raw[off + nf - 1]), 2);
  if (!t.unc) {
    int32_t o = cqe__new(rw, &out, known && r == 0, 0);
    if (t.exc)
      cqe__setfenv(o, 1);
    for (int i = 0; i < nh; ++i)
      cqe__add_dep(o, hs[i]);
    sbuf b = {0};
    sb_addf(&b, "{\"ev\":\"tmpl\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"w\":\"%s\",\"v\":\"", sym, (int)o, ab.p, rw);
    sb_hex(&b, cqe__val(o));
    sb_addf(&b, "\",\"known\":%s}", cqe__known(o) ? "true" : "false");
    cqe_log(b.p);
    free(b.p);
    cqe_val hv;
    cqe__val_init(&hv, 32, 'i');
    hv.w[0] = (uint32_t)o;
    store_val(c->ret, c->rty, &hv);
    cqe__val_free(&hv);
  } else if (c->nargs >= 1) {
    int32_t o = as_i32(&c->raw[0]);
    if (cqe__check(o, sym) == 0) {
      if (strcmp(cqe__w(o), rw) != 0)
        cqe__violation("width_mismatch", o, "%s: out rail %d is %s, the name implies %s", sym, (int)o, cqe__w(o), rw);
      cqe__val_xor(cqe__val(o), &out);
      cqe__mark_written(o);
      sbuf b = {0};
      sb_addf(&b, "{\"ev\":\"unc\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"residue\":\"", sym, (int)o, ab.p);
      sb_hex(&b, cqe__val(o));
      sb_add(&b, "\"}");
      cqe_log(b.p);
      free(b.p);
      if (!cqe__val_iszero(cqe__val(o))) {
        char *hx = cqe__hexa(cqe__val(o));
        cqe__violation("unc_residue", o, "%s: out rail %d holds %s after its _unc", sym, (int)o, hx);
        free(hx);
        cqe__setknown(o, 0);
      } else if (!zero_rule(o, hs, nh) || r != 0) {
        if (r == 0)
          cqe__violation("unc_after_nondiagonal", o,
                         "%s: rail %d or an operand took a non-diagonal gate after rail %d was computed", sym, (int)o,
                         (int)o);
        cqe__setknown(o, 0);
      }
    }
  }
  free(ab.p);
  for (int i = 0; i < nf; ++i)
    if (owned[i])
      cqe__val_free(&args[i]);
  free(owned);
  free(args);
  cqe__val_free(&out);
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

void cqe_dispatch(const char *sym, const char *sig, int32_t nargs, void **argv, void *ret) {
  cqe__init();
  lty rty, ty[64];
  int n = nargs;
  if (nargs < 0 || nargs > 64 || parse_sig(sig, &rty, ty, &n)) {
    cqe__violation("malformed_call", -1, "%s: bad stub signature '%s'", sym, sig);
    return;
  }
  cqe_val raw[64];
  for (int i = 0; i < nargs; ++i)
    load_val(&raw[i], &ty[i], argv[i]);
  if (rty.kind != 'v') {
    cqe_val z;
    cqe__val_init(&z, rty.bits, 'i');
    store_val(ret, &rty, &z);
    cqe__val_free(&z);
  }
  call_t c = {sym, nargs, ty, raw, &rty, ret};
  if (!strncmp(sym, "cq_template_", 12)) {
    template_call(&c, sym);
  } else if (!strncmp(sym, "cqrt_", 5)) {
    cqe_tname t;
    if (!core_gate(&c, sym + 5, NULL, 0)) {
      if (parse_family(sym + 5, &t) == 0)
        family_call(&c, &t);
      else
        cqe__violation("unknown_symbol", -1, "%s: not a cqrt_* symbol of BACKEND_ABI §1", sym);
    }
  } else {
    cqe__violation("unknown_symbol", -1, "%s: not a runtime symbol", sym);
  }
  for (int i = 0; i < nargs; ++i)
    cqe__val_free(&raw[i]);
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

/* Entry of every stub stubgen.py generates for a declared clone __cq_q_<fn>_<mask>[_ctl][_pure][_adj]
 * [_dN][_unc] that nothing links (rule 27). csig is "<fn>|<ret>|<t0>,..." of the C function fn.
 * The clone's ABI arguments (rule 27): [out handle, twin with a non-void result] [pred, _ctl] then per
 * C parameter a scalar (an i32 handle when its mask digit is 1, else the C-typed value) or a pointer
 * as (ptr object, i32 tag, i32 idx, i32 cell count) with three digits (tag, idx, object), then the
 * i32 K, then [one snapshot ptr per pointer whose object digit is 1, twin]. The value is the
 * cq_standin.h function of fn and the scalar arguments (a quantum one by its rail's value), the same
 * function the C oracle defines fn with. The forward clone returns a fresh rail holding it (void: no
 * effect), its _ctl form ignores pred (the stand-in is pure, rule 27), the twin XORs it out of the out
 * rail (void: no effect; the stand-in writes no cell, so the snapshot restore changes nothing). */
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
  _Alignas(16) uint8_t cbuf[64][16]; /* the C arguments of fn, for thunk */
  _Alignas(16) uint8_t rbuf[16];
  void *cargs[64];
  lty rty, ty[64], crty, cty[64];
  int n = nargs, nc = -1;
  const char *bar = strchr(csig, '|');
  char fn[256];
  if (nargs < 0 || nargs > 64 || parse_sig(sig, &rty, ty, &n) || !bar || (size_t)(bar - csig) >= sizeof fn ||
      parse_sig(bar + 1, &crty, cty, &nc) || crty.kind == 'p') {
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
  int unc = 0, ctl = 0;
  for (const char *q = mask + ml; ok && *q;) {
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
    else if (!((len == 4 && !strncmp(q + 1, "pure", 4)) || (len == 3 && !strncmp(q + 1, "adj", 3)) ||
               (len >= 2 && q[1] == 'd' && strspn(q + 2, "0123456789") >= len - 1)))
      ok = 0;
    q += 1 + len;
  }
  if (!ok || ml == 0) {
    cqe__violation("malformed_call", -1, "%s: not a declared clone of %s (CR §1.4, rule 27)", sym, fn);
    goto done;
  }

  /* walk the ABI arguments against the C signature and the mask */
  {
    int a = 0, d = 0, nsnap = 0, nh = 0, known = 1;
    int32_t out_h = -1, hs[64];
    uint64_t h = cq_standin_name(fn, fl);
    sbuf ab = {0};
    sb_add(&ab, "[");
    if (unc ? rty.kind != 'v' : (crty.kind == 'v' ? rty.kind != 'v' : strcmp(rty.ty, "i32") != 0)) {
      cqe__violation("malformed_call", -1, "%s: returns %s; rule 27 says %s", sym, rty.ty,
                     (unc || crty.kind == 'v') ? "void" : "an i32 handle");
      ok = 0;
    }
    if (ok && unc && crty.kind != 'v') {
      if (a >= nargs || strcmp(ty[a].ty, "i32") != 0)
        ok = 0;
      else
        out_h = as_i32(&raw[a++]);
    }
    if (ok && ctl) {
      if (a >= nargs || strcmp(ty[a].ty, "i32") != 0 || cqe__check(as_i32(&raw[a]), sym) < 0)
        ok = 0;
      ++a;
    }
    for (int j = 0; ok && j < nc; ++j) {
      if (cty[j].kind == 'p') {
        if (thunk) { /* stubgen.py never pairs a thunk with a pointer parameter */
          ok = 0;
          break;
        }
        if (a + 4 > nargs || ty[a].kind != 'p' || strcmp(ty[a + 1].ty, "i32") || strcmp(ty[a + 2].ty, "i32") ||
            strcmp(ty[a + 3].ty, "i32") || d + 3 > (int)ml) {
          ok = 0;
          break;
        }
        for (int k = 0; k < 2; ++k) /* a quantum tag or idx is a handle */
          if (mask[d + k] == '1' && cqe__check(as_i32(&raw[a + 1 + k]), sym) < 0)
            ok = 0;
        nsnap += unc && mask[d + 2] == '1';
        a += 4;
        d += 3;
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
    /* K. A clone of a host function may also be a rule 18 lift of the injected libc/libm source (CR §8
     * item 14, 175: __cq_q_exp_1(i32)), which has none (cq-aou6). */
    if (thunk && a == nargs) /* no pointer parameter, so no snapshot either */
      ;
    else if (ok && (a >= nargs || strcmp(ty[a].ty, "i32") != 0))
      ok = 0;
    else
      ++a;
    for (int k = 0; ok && k < nsnap; ++k, ++a)
      if (a >= nargs || ty[a].kind != 'p')
        ok = 0;
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
      lty_wtok(&crty, wt, sizeof wt);
      cqe_val v;
      if (thunk) { /* the host's fn (cq-aou6) */
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
        cqe__mark_written(out_h);
        sbuf b = {0};
        sb_addf(&b, "{\"ev\":\"unc\",\"sym\":\"%s\",\"out\":%d,\"args\":%s,\"residue\":\"", sym, (int)out_h, ab.p);
        sb_hex(&b, cqe__val(out_h));
        sb_add(&b, "\"}");
        cqe_log(b.p);
        free(b.p);
        if (!cqe__val_iszero(cqe__val(out_h))) {
          char *hx = cqe__hexa(cqe__val(out_h));
          cqe__violation("unc_residue", out_h, "%s: out rail %d holds %s after its twin", sym, (int)out_h, hx);
          free(hx);
          cqe__setknown(out_h, 0);
        } else if (!zero_rule(out_h, hs, nh)) {
          cqe__violation("unc_after_nondiagonal", out_h,
                         "%s: rail %d or an operand took a non-diagonal gate after rail %d was computed", sym,
                         (int)out_h, (int)out_h);
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
    if (core_gate(NULL, sym + 5, cls, ncls))
      return 0;
    if (parse_family(sym + 5, &t) == 0) {
      snprintf(cls, ncls, "family:%s", t.op);
      return 0;
    }
  }
  return -1;
}
