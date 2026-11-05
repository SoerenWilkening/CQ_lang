/* Checker core (cq-w0-chk-core): the rail store of the §6.1 classical basis-state evaluator, the
 * JSONL trace, violations, and the cqe.h API that families use. Symbol handling (the stub entry
 * cqe_dispatch, core-gate semantics, the template registry and parser) is in dispatch.c.
 *
 * Rails. A handle names one rail for the whole run; handles are never reused (1, 2, 3, ...). Handle 0
 * is reserved (CR §1.1, BACKEND_ABI §1): no allocation returns it, it means "no rail", and a gate
 * handed it is a bad_handle. Handles are classical values of the host program (compared, selected,
 * stored); the evaluator sees only the ones passed to it. A rail
 * has a width token ("i32", "f80", ...), a basis value (cqe_val, little-endian 64-bit words, bits
 * above the width zero), a liveness state and its known flag: BACKEND_ABI §0's classical-valued (holds
 * one basis value the backend knows; §1.2: cqrt_free may reset it whatever value it holds). Known: a
 * seed (cqrt_alloc), a seed after an uncontrolled xorc, the result of a template, core gate or bus access
 * whose operands, controls and cells are all known, a measured rail, and a rail an XOR-into write
 * (template _unc, load _unc, copy, and/or/xor_i1) returned to 0 with no non-diagonal gate (Ry) on the
 * target or any source after the target's or the sources' creation (dispatch.c, cqe__zero_rule). A rotated
 * rail is not known (Q17). cqrt_free is legal on a known rail and on a rail a bus swap left at 0 (the
 * rail the cells' 0 went to, ABI §1.10 Undo 2: cqe__set_busz); anything else is dirty_free.
 *
 * Trace. One JSON object per line, to the file named by $CQE_TRACE (stderr when unset), flushed
 * per line so a crash keeps every event before it. The frozen events of cq-arch are written with
 * their frozen fields; some carry additive fields (documented at each writer). The exit event is
 * written by an atexit handler registered before any other runtime handler, so it comes last.
 * Under the batch driver (run.py) one worker process runs every sample in turn (shots, at the end of
 * this file); the end-of-shot handlers and the exit event run once per sample, and the trace is
 * flushed at the end of each sample instead of per line.
 *
 * Exit roles (event "exit", field "role" of each live rail): measured, abort, tape (an effect entry's result
 * rail too, rt_tape.c), tape_slot (a bus store's slot, rule 5), overtaken (a load copy un-copied
 * and not freed, rule 5), frozen (rotated, not measured, or a rule-6 image carrying a rotated register's
 * content: cqe__carry, cq-qhow), store_kept (a value or control rail of a bus store still live, rule 5
 * sentence 3), kept_entangled (cq-arch A4: a rail one of whose direct sources received
 * a non-diagonal gate or a measurement after the rail was written), output (its handle sits in
 * output memory at exit, mark_outputs; cq-tt2j), fenv_mode (a rail an _rmq template took as its
 * rounding mode; rule 23), fenv_flags (an _exc template's result or a rail written from one: the
 * flags lineage of rule 23), seed (an alloc never written since), garbage (anything else). Each live
 * rail also carries "known" (its known-basis flag, above; cq-tt2j: CR §6 item 1's leak rule reads it).
 */
#include <errno.h>
#include <fcntl.h>
#include <fenv.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <unistd.h>

#include "cqe.h"

/* ---- CR §2 fp -> int for the lowered module's classical fptosi/fptoui (cq-ltoq) --------------
 * run.py (totalize_module) rewrites each classical fptosi/fptoui of the lowered module to a call of
 * one of these, the same rows the C oracle's runtime computes for the C program (CR §2: c32/c64 are
 * cvtt with the indefinite INT_MIN of their width; f80 is x87 fistp). w is 8, 16, 32 or 64; sgn is
 * 1 for fptosi. f16/bf16/f32 arrive widened to f64 exactly. */
static int64_t tot_c32(double x) {
  if (x > -2147483649.0 && x < 2147483648.0)
    return (int32_t)x;
  feraiseexcept(FE_INVALID);
  return INT32_MIN;
}
static int64_t tot_c64(double x) {
  if (x >= -9223372036854775808.0 && x < 9223372036854775808.0)
    return (int64_t)x;
  feraiseexcept(FE_INVALID);
  return INT64_MIN;
}
int64_t __cqe_fpto64(double x, int32_t w, int32_t sgn) {
  if (sgn)
    return w == 64 ? tot_c64(x) : tot_c32(x);
  if (w <= 16)
    return tot_c32(x);
  if (w == 32)
    return tot_c64(x);
  int64_t r1 = tot_c64(x), r2 = tot_c64(x - 9223372036854775808.0);
  return r1 | (r2 & (r1 >> 63));
}
static int64_t tot_fist(long double x, int b) {
  long double lim = b == 16 ? 32768.0L : b == 32 ? 2147483648.0L : 9223372036854775808.0L;
  if (x > -lim - 1.0L && x < lim)
    return (int64_t)x;
  feraiseexcept(FE_INVALID);
  return b == 16 ? INT16_MIN : b == 32 ? INT32_MIN : INT64_MIN;
}
int64_t __cqe_fpto80(long double x, int32_t w, int32_t sgn) {
  if (sgn)
    return w <= 16 ? tot_fist(x, 16) : tot_fist(x, w);
  if (w <= 16)
    return tot_fist(x, 32);
  if (w == 32)
    return tot_fist(x, 64);
  if (x < 9223372036854775808.0L)
    return tot_fist(x, 64);
  return (int64_t)((uint64_t)tot_fist(x - 9223372036854775808.0L, 64) ^ 0x8000000000000000ULL);
}

/* ---- the default environment for a plain fp operation (cq-6ady) -----------------------------
 * run.py (default_env_module) brackets each non-constrained fp operation of a lowered module that
 * touches the fp environment by these two (owner ruling on cq-0r1i: round-to-nearest, no flags):
 * the live environment is saved, FE_DFL_ENV installed, and the saved one put back after the
 * operation, so its flags vanish. Never nested. */
static fenv_t fpdfl_saved;
void __cqe_fpdfl_enter(void) {
  fegetenv(&fpdfl_saved);
  fesetenv(FE_DFL_ENV);
}
void __cqe_fpdfl_leave(void) { fesetenv(&fpdfl_saved); }

/* ---- values ------------------------------------------------------------------------------ */

uint32_t cqe__nwords(uint32_t bits) { return bits ? (bits + 63) / 64 : 1; }

static void *xcalloc(size_t n, size_t sz) {
  void *p = calloc(n ? n : 1, sz);
  if (!p) {
    fprintf(stderr, "cq: chk-core: out of memory\n");
    abort();
  }
  return p;
}

/* Bits and kind of a width token: i<N> (N >= 1, no leading zero), f16, f32, f64, f80, bf16 (CR §1.1;
 * bits 16 and kind 'f' like f16, so a consumer that needs the format reads the token). 0 if malformed. */
uint32_t cqe__wtok_bits(const char *w, char *kind) {
  if (!w)
    return 0;
  if (w[0] == 'f' || w[0] == 'b') {
    static const char *f[] = {"f16", "f32", "f64", "f80", "bf16"};
    static const uint32_t b[] = {16, 32, 64, 80, 16};
    for (int i = 0; i < 5; ++i)
      if (strcmp(w, f[i]) == 0) {
        if (kind)
          *kind = 'f';
        return b[i];
      }
    return 0;
  }
  if (w[0] != 'i' || w[1] < '1' || w[1] > '9')
    return 0;
  uint64_t n = 0;
  for (const char *p = w + 1; *p; ++p) {
    if (*p < '0' || *p > '9')
      return 0;
    n = n * 10 + (uint64_t)(*p - '0');
    if (n > (1u << 24))
      return 0;
  }
  if (kind)
    *kind = 'i';
  return (uint32_t)n;
}

void cqe__val_init(cqe_val *v, uint32_t bits, char kind) {
  v->bits = bits;
  v->kind = kind;
  v->nw = cqe__nwords(bits);
  v->w = xcalloc(v->nw, sizeof *v->w);
}

void cqe__val_free(cqe_val *v) {
  free(v->w);
  v->w = NULL;
  v->nw = 0;
}

void cqe__val_mask(cqe_val *v) {
  uint32_t full = v->bits / 64, rem = v->bits % 64;
  for (uint32_t i = 0; i < v->nw; ++i) {
    if (i > full || (i == full && rem == 0))
      v->w[i] = 0;
    else if (i == full)
      v->w[i] &= ((uint64_t)1 << rem) - 1;
  }
}

/* dst ^= low dst->bits of src (src may be narrower or wider). */
void cqe__val_xor(cqe_val *dst, const cqe_val *src) {
  for (uint32_t i = 0; i < dst->nw && i < src->nw; ++i)
    dst->w[i] ^= src->w[i];
  cqe__val_mask(dst);
}

void cqe__val_copy_into(cqe_val *dst, const cqe_val *src) {
  memset(dst->w, 0, dst->nw * sizeof *dst->w);
  cqe__val_xor(dst, src);
}

int cqe__val_iszero(const cqe_val *v) {
  for (uint32_t i = 0; i < v->nw; ++i)
    if (v->w[i])
      return 0;
  return 1;
}

/* "0x..." lowercase, no leading zeros; buf must hold 3 + 16 * nw bytes. */
char *cqe__hex(const cqe_val *v, char *buf) {
  char *p = buf;
  *p++ = '0';
  *p++ = 'x';
  int started = 0;
  for (uint32_t i = v->nw; i-- > 0;) {
    if (!started) {
      if (v->w[i] == 0 && i > 0)
        continue;
      p += sprintf(p, "%llx", (unsigned long long)v->w[i]);
      started = 1;
    } else {
      p += sprintf(p, "%016llx", (unsigned long long)v->w[i]);
    }
  }
  *p = 0;
  return buf;
}

/* Heap hex of a value (caller frees). */
char *cqe__hexa(const cqe_val *v) { return cqe__hex(v, xcalloc(3 + 16 * (size_t)v->nw + 1, 1)); }

/* ---- trace ------------------------------------------------------------------------------- */

static FILE *trace_f;
static int inited;
static unsigned long nviolations;
static int shot_muted;    /* a batch runner's own end (shots, end of file): nothing more is logged */
static int shot_buffered; /* a shot worker: the trace is flushed at the end of each sample, not per line */

/* Disk caps (cq-3fjt: one run's trace once reached 15 GB, a sample that looped over violations).
 * A running sample that logs more than $CQE_SHOT_TRACE_MAX bytes (default 32 MiB), or whose stdout
 * or stderr capture passes $CQE_SHOT_OUTPUT_MAX bytes (default 8 MiB), ends there with a "trace_cap"
 * violation, as by signal SIGXFSZ (shot_over, in the shots below). A worker whose trace file passed
 * $CQE_TRACE_ROTATE bytes (default 64 MiB) at the end of a sample ends the runner with status 99 and
 * "cq: chk-core: trace rotation" on stderr; run.py goes on with a fresh runner and a fresh trace.
 * RLIMIT_FSIZE ($CQE_FILE_MAX, default 256 MiB, SIGXFSZ ignored) is the backstop for every file the
 * runner writes. 0 disables a cap. */
static unsigned long long shot_trace_n;               /* bytes the running sample logged */
static unsigned long long shot_trace_cap = 32ULL << 20;
static unsigned long long shot_output_cap = 8ULL << 20;
static unsigned long long trace_rotate = 64ULL << 20;
static void shot_over(const char *what, unsigned long long cap); /* shots, below */
/* The violation cap (cq-r8-chk176): a running sample that logs more than $CQE_SHOT_VIOL_MAX violations
 * (default 256; 0: no cap) ends there with a "violation_cap" violation, as at a disk cap. The sample
 * already fails (any violation does); the cap only stops a lowering that loops over violations (176:
 * 350k bad_handle/pop_empty events, 32 MiB a sample) from costing seconds and hundreds of MB per sample
 * in the trace, its parse and the comparison's reasons. */
static unsigned long long shot_viol_n;                /* violations the running sample logged */
static unsigned long long shot_viol_cap = 256;
static void shot_over_violations(void);              /* shots, below */

static unsigned long long env_bytes(const char *name, unsigned long long dflt) {
  const char *v = getenv(name);
  if (!v || !*v)
    return dflt;
  unsigned long long n = strtoull(v, NULL, 10);
  return n ? n : ~0ULL;
}

static void trace_count(size_t n) {
  shot_trace_n += n;
  if (shot_trace_n > shot_trace_cap)
    shot_over("trace", shot_trace_cap);
}

static void at_exit_handler(void);

/* Compact trace (cq-8m6v, $CQE_COMPACT=1, set by run.py's runner): only the events run.py reads
 * reach the trace (rotations, measure, ret, violation, exit, effect, the shot frames, rt-bus's bus,
 * cells and out_mem events, rt-tape's end-of-shot events, and the free events of the setup and the dirty ones of a sample);
 * a sample's frees are summed up in its shot_end frame (cqe__free_note). Without it every event is
 * written, as before. */
static int compact;

static int keep_event(const char *s) {
  static const char pre[] = "{\"ev\":\"";
  if (!compact || strncmp(s, pre, sizeof pre - 1) != 0)
    return 1;
  const char *n = s + sizeof pre - 1;
  static const char *keep[] = {"ry\"", "ry_qangle\"", "phase\"", "phase_qangle\"", "measure\"", "ret\"",
                               "violation\"", "exit\"", "effect\"", "shot\"", "shot_end\"", "free\"",
                               "bus\"", "cells\"", "out_mem\"", "tape\",\"op\":\"shot\""};
  for (size_t i = 0; i < sizeof keep / sizeof *keep; ++i)
    if (!strncmp(n, keep[i], strlen(keep[i])))
      return 1;
  return 0;
}

void cqe__init(void) {
  if (inited)
    return;
  inited = 1;
  const char *cm = getenv("CQE_COMPACT");
  compact = cm && !strcmp(cm, "1");
  shot_trace_cap = env_bytes("CQE_SHOT_TRACE_MAX", shot_trace_cap);
  shot_output_cap = env_bytes("CQE_SHOT_OUTPUT_MAX", shot_output_cap);
  shot_viol_cap = env_bytes("CQE_SHOT_VIOL_MAX", shot_viol_cap);
  trace_rotate = env_bytes("CQE_TRACE_ROTATE", trace_rotate);
  unsigned long long fmax = env_bytes("CQE_FILE_MAX", 256ULL << 20);
  struct rlimit rl;
  if (fmax != ~0ULL && getrlimit(RLIMIT_FSIZE, &rl) == 0 && (rl.rlim_cur == RLIM_INFINITY || rl.rlim_cur > fmax)) {
    rl.rlim_cur = rl.rlim_max != RLIM_INFINITY && rl.rlim_max < fmax ? rl.rlim_max : (rlim_t)fmax;
    setrlimit(RLIMIT_FSIZE, &rl);
  }
  signal(SIGXFSZ, SIG_IGN); /* a write past the limit fails (EFBIG); the caps above say so first */
  const char *path = getenv("CQE_TRACE");
  if (path && *path) {
    trace_f = fopen(path, "w");
    if (!trace_f) {
      fprintf(stderr, "cq: chk-core: cannot open CQE_TRACE '%s'\n", path);
      exit(97);
    }
  } else {
    trace_f = stderr;
  }
  atexit(at_exit_handler);
}

__attribute__((constructor(101))) static void cqe__ctor(void) { cqe__init(); }

void cqe_log(const char *json_object) {
  cqe__init();
  if (shot_muted || !keep_event(json_object))
    return;
  fputs(json_object, trace_f);
  fputc('\n', trace_f);
  if (!shot_buffered)
    fflush(trace_f);
  trace_count(strlen(json_object) + 1);
}

/* printf-style log of one line. */
void cqe__logf(const char *fmt, ...) {
  cqe__init();
  if (shot_muted || !keep_event(fmt)) /* every format starts with its literal {"ev":"<kind>" */
    return;
  va_list ap;
  va_start(ap, fmt);
  int n = vfprintf(trace_f, fmt, ap);
  va_end(ap);
  fputc('\n', trace_f);
  if (!shot_buffered)
    fflush(trace_f);
  trace_count(n > 0 ? (size_t)n + 1 : 1);
}

/* JSON string body escaping into a heap buffer. */
static char *json_escape(const char *s) {
  size_t n = strlen(s);
  char *o = xcalloc(6 * n + 1, 1), *p = o;
  for (; *s; ++s) {
    unsigned char c = (unsigned char)*s;
    if (c == '"' || c == '\\') {
      *p++ = '\\';
      *p++ = (char)c;
    } else if (c < 0x20) {
      p += sprintf(p, "\\u%04x", c);
    } else {
      *p++ = (char)c;
    }
  }
  return o;
}

/* A violation: {"ev":"violation","what","h"} plus an additive "msg". h < 0 is written as null. */
void cqe__violation(const char *what, int32_t h, const char *fmt, ...) {
  char msg[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(msg, sizeof msg, fmt ? fmt : "", ap);
  va_end(ap);
  char *e = json_escape(msg);
  ++nviolations;
  if (h > 0)
    cqe__logf("{\"ev\":\"violation\",\"what\":\"%s\",\"h\":%d,\"msg\":\"%s\"}", what, (int)h, e);
  else
    cqe__logf("{\"ev\":\"violation\",\"what\":\"%s\",\"h\":null,\"msg\":\"%s\"}", what, e);
  free(e);
  if (++shot_viol_n > shot_viol_cap)
    shot_over_violations();
}

void cqe_fail(const char *fmt, ...) {
  char msg[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(msg, sizeof msg, fmt, ap);
  va_end(ap);
  cqe__violation("fail", -1, "%s", msg);
}

unsigned long cqe__violations(void) { return nviolations; }

/* ---- rails ------------------------------------------------------------------------------- */

typedef struct {
  char w[8];
  cqe_val v;
  uint8_t live, known, measured, frozen, written, seed;
  uint8_t role;  /* 0 none, 1 abort, 2 tape, 4 tape_slot, 5 overtaken */
  uint8_t busz;  /* a bus swap left it at 0 and nothing wrote it since (cqe__set_busz) */
  uint8_t store_kept; /* the value or control rail of a bus store (rule 5 sentence 3) */
  uint8_t fenv;  /* cq-tt2j, rule 23: 1 flags lineage (an _exc result or written from one), 2 a mode operand */
  uint8_t out;   /* cq-tt2j: at exit, its handle sits in a cell of output memory (mark_outputs) */
  uint8_t image; /* cq-qhow: carries a frozen register's content (cqe__carry): a rule-6 image, FROZEN */
  uint64_t t_create, t_write, t_nd, t_meas;                       /* event clock; 0 = never */
  uint64_t ry_t, ry_ang;  /* cq-3o3v: the last firing Ry on the rail (clock after it, angle bits) */
  uint64_t *ry_pre, *ry_post; /* its target's value before and after it (v.nw words each) */
  int32_t *deps;
  uint32_t ndeps, capdeps;
} rail_t;

#define CQE_RAIL_LIMIT 0x51000000u /* rail handles stay below the bus handle (rt_bus.c) */
static rail_t *rails; /* rails[h], h >= 1 */
static uint32_t nrails, caprails;
static uint64_t clock_;

uint64_t cqe__tick(void) { return ++clock_; }
uint32_t cqe__nrails_peek(void) { return nrails; }

/* cq-4593 (BACKEND_ABI 1.13): a gate recorded inside a cq_invert region whose forward form makes a fresh
 * rail got that rail at once (allocations keep their place, at |0>); when the gate is replayed, the next
 * cqe__new is that rail: init is XORed into it (dispatch.c, cqe__prealloc). */
static int32_t prealloc_h;
void cqe__prealloc(int32_t h) { prealloc_h = h; }
/* The replayed compute of a reserved rail: the rail's value is made now (its known-basis reference). */
void cqe__recreated(int32_t h) {
  if (h >= 1 && (uint32_t)h <= nrails)
    rails[h].t_create = rails[h].t_write = cqe__tick();
}

int32_t cqe__new(const char *w, const cqe_val *init, int known, int seed) {
  cqe__init();
  if (prealloc_h > 0) {
    int32_t h = prealloc_h;
    prealloc_h = 0;
    if ((uint32_t)h > nrails || !rails[h].live) {
      cqe__violation("bad_handle", h, "cq_invert replay: rail %d is not live", (int)h);
    } else {
      if (w && strcmp(rails[h].w, w) != 0)
        cqe__violation("width_mismatch", h, "cq_invert replay: rail %d is %s, the gate makes %s", (int)h, rails[h].w, w);
      if (init)
        cqe__val_xor(&rails[h].v, init);
      rails[h].known = rails[h].known && known;
      rails[h].t_write = cqe__tick();
      return h;
    }
  }
  char kind = 0;
  uint32_t bits = cqe__wtok_bits(w, &kind);
  if (!bits) {
    cqe__violation("bad_width", -1, "rail width token '%s' is not i<N>, f16, f32, f64, f80 or bf16", w ? w : "(null)");
    bits = 1;
    kind = 'i';
    w = "i1";
  }
  if (nrails + 2 > caprails) {
    caprails = caprails ? 2 * caprails : 256;
    rails = realloc(rails, caprails * sizeof *rails);
    if (!rails)
      abort();
  }
  if (nrails + 1 >= CQE_RAIL_LIMIT) {
    fprintf(stderr, "cq: chk-core: rail handles exhausted (limit 0x%x, the bus handle)\n",
            (unsigned)CQE_RAIL_LIMIT);
    abort();
  }
  int32_t h = (int32_t)++nrails;
  rail_t *r = &rails[h];
  memset(r, 0, sizeof *r);
  snprintf(r->w, sizeof r->w, "%s", w);
  cqe__val_init(&r->v, bits, kind);
  if (init)
    cqe__val_xor(&r->v, init);
  r->live = 1;
  r->known = known ? 1 : 0;
  r->seed = seed ? 1 : 0;
  r->t_create = r->t_write = cqe__tick();
  return h;
}

/* 0: h names a live rail. 1: freed (use_after_free logged). -1: no such rail (bad_handle logged). */
int cqe__check(int32_t h, const char *ctx) {
  cqe__init();
  if (h == 0) { /* CR §1.1 (f684858): handle 0 is reserved, never allocated: "no rail" */
    cqe__violation("bad_handle", -1, "%s: handle 0 is reserved (no rail on this path, CR §1.1) and names no rail", ctx);
    return -1;
  }
  if (h < 1 || (uint32_t)h > nrails) {
    cqe__violation("bad_handle", h > 0 ? h : -1, "%s: handle %d names no rail", ctx, (int)h);
    return -1;
  }
  if (!rails[h].live) {
    cqe__violation("use_after_free", h, "%s: rail %d was freed", ctx, (int)h);
    return 1;
  }
  return 0;
}

/* Quiet existence test (no violation). */
int cqe__exists(int32_t h) { return h >= 1 && (uint32_t)h <= nrails; }

cqe_val *cqe__val(int32_t h) { return &rails[h].v; }
const char *cqe__w(int32_t h) { return rails[h].w; }
int cqe__known(int32_t h) { return rails[h].known; }
void cqe__setknown(int32_t h, int k) { rails[h].known = k ? 1 : 0; }
uint64_t cqe__created(int32_t h) { return rails[h].t_create; }
uint64_t cqe__last_nd(int32_t h) { return rails[h].t_nd; }
int cqe__measured(int32_t h) { return rails[h].measured; }
int cqe__frozen(int32_t h) { return rails[h].frozen; }
int cqe__role(int32_t h) { return rails[h].role; }
void cqe__setfenv(int32_t h, int bits) { rails[h].fenv |= (uint8_t)bits; }
void cqe__setrole(int32_t h, int role) { rails[h].role = (uint8_t)role; }
void cqe__set_busz(int32_t h) { rails[h].busz = 1; }
int cqe__busz(int32_t h) { return rails[h].busz; }
void cqe__set_store_kept(int32_t h) { rails[h].store_kept = 1; }

void cqe__mark_written(int32_t h) {
  rails[h].written = 1;
  rails[h].busz = 0;
  rails[h].t_write = cqe__tick();
}
/* cq-3o3v: a firing Ry on h that took a C reach changed its value from pre to the reach's value. A
 * later firing Ry on h with the negated angle, with h neither written nor changed since and no C
 * reach of its own, is that Ry's adjoint in this branch (CR rule 10's un-prep): Ry(-θ)·Ry(θ) = I, so
 * h holds pre again (cqe__ry_unprep). */
void cqe__ry_note(int32_t h, uint64_t angle, const cqe_val *pre) {
  rail_t *r = &rails[h];
  uint32_t nw = r->v.nw;
  if (!r->ry_pre) {
    r->ry_pre = xcalloc(nw ? nw : 1, sizeof *r->ry_pre);
    r->ry_post = xcalloc(nw ? nw : 1, sizeof *r->ry_post);
  }
  memcpy(r->ry_pre, pre->w, nw * sizeof *r->ry_pre);
  memcpy(r->ry_post, r->v.w, nw * sizeof *r->ry_post);
  r->ry_ang = angle;
  r->ry_t = cqe__tick();
}
int cqe__ry_unprep(int32_t h, uint64_t angle) {
  rail_t *r = &rails[h];
  if (!r->ry_t || r->t_write > r->ry_t || angle != (r->ry_ang ^ (1ULL << 63)) ||
      memcmp(r->ry_post, r->v.w, r->v.nw * sizeof *r->ry_post) != 0)
    return 0;
  memcpy(r->v.w, r->ry_pre, r->v.nw * sizeof *r->ry_pre);
  r->ry_t = 0;
  return 1;
}
void cqe__ry_forget(int32_t h) { rails[h].ry_t = 0; }
void cqe__mark_nd(int32_t h) {
  rails[h].frozen = 1;
  rails[h].busz = 0;
  rails[h].t_nd = cqe__tick();
}
/* CR rule 2, BACKEND_ABI 1.3 (cq-ihlt): measuring a measured rail again is a classical re-read of
 * its outcome; the rail's measurement (and its time, which kept_entangled reads) stays the first. */
void cqe__mark_measured(int32_t h) {
  if (rails[h].measured)
    return;
  rails[h].measured = 1;
  rails[h].known = 1;
  rails[h].t_meas = cqe__tick();
}
/* CR rule 19 / §6 item 1 (cq-qhow): a frozen register (rotated) is never written in place again
 * except to clean it, and rule 6 cleans a dead register x against its image r: t = g(r); x ^= t
 * (copy); t _unc against r. A write into a frozen rail, or into a rail already carrying one's content,
 * therefore moves that content into the rails it is written from: copy's source, an _unc's or gate's
 * operand rails. Those carry it (image); a live one at exit is FROZEN like the register itself (rule
 * 19: "its minted register or that register's rule-6 image is a FROZEN result the caller keeps"),
 * across calls, since the facts are the run's, not the function's. A measured rail is classical and
 * carries nothing. Over-approximation: an _unc with several quantum operands marks them all. */
void cqe__carry(int32_t into, const int32_t *srcs, int n) {
  rail_t *d = &rails[into];
  if (d->measured || !(d->frozen || d->image))
    return;
  for (int i = 0; i < n; ++i)
    if (srcs[i] != into && !rails[srcs[i]].measured)
      rails[srcs[i]].image = 1;
}

void cqe__add_dep(int32_t h, int32_t src) {
  rail_t *r = &rails[h];
  r->fenv |= rails[src].fenv & 1; /* cq-tt2j: a rail written from the flags is flags (rule 23 lineage) */
  for (uint32_t i = 0; i < r->ndeps; ++i)
    if (r->deps[i] == src)
      return;
  if (r->ndeps == r->capdeps) {
    r->capdeps = r->capdeps ? 2 * r->capdeps : 4;
    r->deps = realloc(r->deps, r->capdeps * sizeof *r->deps);
    if (!r->deps)
      abort();
  }
  r->deps[r->ndeps++] = src;
}

void cqe__free(int32_t h) {
  rails[h].live = 0;
  /* a freed rail's role is never asked (the exit event lists live rails); its dependency list goes
   * back to the sample arena's free lists for the next rail (cq-8m6v). Its event times stay: a live
   * rail's role reads them. */
  free(rails[h].deps);
  rails[h].deps = NULL;
  rails[h].ndeps = rails[h].capdeps = 0;
}

/* ---- cqe.h rail API (families) ------------------------------------------------------------- */

int32_t cqe_new_rail(const char *w, const cqe_val *init, int known) { return cqe__new(w, init, known, 0); }

const cqe_val *cqe_rail(int32_t h) {
  if (cqe__check(h, "cqe_rail") != 0) /* C1: a freed or unknown handle is a violation and NULL */
    return NULL;
  return &rails[h].v;
}

void cqe_xor_into(int32_t h, const cqe_val *v) {
  if (cqe__check(h, "cqe_xor_into") < 0 || !v)
    return;
  cqe__val_xor(&rails[h].v, v);
  cqe__mark_written(h);
}

void cqe_set_known(int32_t h, int known) {
  if (cqe__check(h, "cqe_set_known") < 0)
    return;
  rails[h].known = known ? 1 : 0;
}

/* ---- exit -------------------------------------------------------------------------------- */

static const char *exit_role(int32_t h) {
  rail_t *r = &rails[h];
  if (r->measured)
    return "measured";
  if (r->role == 1)
    return "abort";
  if (r->role == 2)
    return "tape";
  if (r->role == 4)
    return "tape_slot";
  if (r->role == 5)
    return "overtaken";
  if (r->frozen || r->image)
    return "frozen";
  if (r->store_kept)
    return "store_kept";
  for (uint32_t i = 0; i < r->ndeps; ++i) {
    rail_t *s = &rails[r->deps[i]];
    if ((s->t_nd && s->t_nd > r->t_write) || (s->t_meas && s->t_meas > r->t_write))
      return "kept_entangled";
  }
  if (r->out)
    return "output";
  if (r->fenv & 2)
    return "fenv_mode";
  if (r->fenv & 1)
    return "fenv_flags";
  if (r->seed && !r->written)
    return "seed";
  return "garbage";
}

/* ---- output memory at exit (cq-tt2j) -------------------------------------------------------
 * CR §6 item 1: a rail live at exit whose handle sits in output memory is a named output, never a
 * leak (orchestrator decision on cq-tt2j: a host or slot cell of an output object or out-parameter,
 * a global, the object a returned pointer reaches). run.py (cells_module) has the lowered module
 * call __cqe_cell_note(p, n) after each store of a type holding an i32 (the handle width) and each
 * memory intrinsic (n bytes at p): the cells the module wrote. At exit every noted cell that is still
 * allocated memory is read as 4-byte words; a word naming a live rail marks it "output". Not output
 * memory: a cell in a dead stack frame (below the driver's frame, R->stack_lo: every frame of the
 * lowered module has returned at the end of a sample) and a cell of a freed sample-arena block. The
 * driver's objects (its frame, statics), the module's globals and live heap blocks are output
 * memory. Writes outside the lowered module (the driver, the runtime) are not noted: the driver's
 * memory-borne inputs are rails it allocates itself, registers kept anyway. A classical word that
 * happens to equal a live handle in such a cell also marks the rail (a missed leak, never a false
 * one). */
typedef struct {
  uintptr_t p;
  uint64_t n;
} cellnote;
static cellnote *cn_tab; /* open addressing on p; in __DATA and the sample arena: reset every shot */
static size_t cn_cap, cn_n;

static size_t cn_slot(cellnote *tab, size_t cap, uintptr_t p) {
  size_t i = (size_t)((p >> 2) * 0x9E3779B97F4A7C15ULL) & (cap - 1);
  while (tab[i].p && tab[i].p != p)
    i = (i + 1) & (cap - 1);
  return i;
}

void __cqe_cell_note(void *ptr, int64_t n) {
  uintptr_t p = (uintptr_t)ptr;
  if (!p || n <= 0)
    return;
  if (2 * (cn_n + 1) > cn_cap) {
    size_t cap = cn_cap ? 2 * cn_cap : 256;
    cellnote *tab = calloc(cap, sizeof *tab);
    if (!tab)
      abort();
    for (size_t i = 0; i < cn_cap; ++i)
      if (cn_tab[i].p)
        tab[cn_slot(tab, cap, cn_tab[i].p)] = cn_tab[i];
    free(cn_tab);
    cn_tab = tab;
    cn_cap = cap;
  }
  size_t i = cn_slot(cn_tab, cn_cap, p);
  if (!cn_tab[i].p) {
    cn_tab[i].p = p;
    ++cn_n;
  }
  if ((uint64_t)n > cn_tab[i].n)
    cn_tab[i].n = (uint64_t)n;
}

static int cell_dead(uintptr_t p); /* below, beside the arena */

static void mark_outputs(void) {
  for (size_t i = 0; i < cn_cap; ++i) {
    uintptr_t p = cn_tab[i].p;
    if (!p || cell_dead(p))
      continue;
    for (uintptr_t q = (p + 3) & ~(uintptr_t)3; q + 4 <= p + cn_tab[i].n; q += 4) {
      int32_t v;
      memcpy(&v, (const void *)q, 4);
      if (v >= 1 && (uint32_t)v <= nrails && rails[v].live)
        rails[v].out = 1;
    }
  }
}

static void at_exit_handler(void) {
  if (shot_muted)
    return;
  size_t cap = 64, len = 0;
  char *buf = xcalloc(cap, 1);
#define APPEND(...)                                                                                \
  do {                                                                                             \
    int need_ = snprintf(NULL, 0, __VA_ARGS__);                                                    \
    while (len + (size_t)need_ + 1 > cap) {                                                        \
      cap *= 2;                                                                                    \
      buf = realloc(buf, cap);                                                                     \
      if (!buf)                                                                                    \
        abort();                                                                                   \
    }                                                                                              \
    len += (size_t)snprintf(buf + len, cap - len, __VA_ARGS__);                                    \
  } while (0)
  mark_outputs();
  APPEND("{\"ev\":\"exit\",\"live\":[");
  int first = 1;
  for (uint32_t h = 1; h <= nrails; ++h) {
    if (!rails[h].live)
      continue;
    char *hx = cqe__hexa(&rails[h].v);
    APPEND("%s{\"h\":%u,\"w\":\"%s\",\"v\":\"%s\",\"role\":\"%s\",\"known\":%s}", first ? "" : ",", h,
           rails[h].w, hx, exit_role((int32_t)h), rails[h].known ? "true" : "false");
    free(hx);
    first = 0;
  }
  APPEND("],\"violations\":%lu}", nviolations);
#undef APPEND
  cqe_log(buf);
  free(buf);
  if (shot_buffered) /* a shot worker's sample ends here; the trace stays open for the next */
    return;
  if (trace_f && trace_f != stderr)
    fclose(trace_f);
  trace_f = stderr;
}

/* ---- shots (cq-e2i9): one process runs a batch, every sample from the same post-setup state ------
 *
 * run.py renders the driver (drivers.driver_source) with
 *   before_call  if (sigsetjmp(*cqe__shot_jb(), 1) != 0) cqe__shot_resume(); else if (cqe__shot_enter(CQD_SAMPLE)) {
 *   after_call   cqe__shot_end(); }
 * The process runs the setup once. At its first record it becomes the server: it forks one worker and
 * from then on only waits and skips records. The worker runs the records in-process, one shot each,
 * and between two shots puts back everything a sample can change, so that sample i+1 starts from
 * exactly the state sample i started from (the server's post-setup state, as a process of its own
 * per sample had it):
 *   - the executable's writable data (__DATA: __data, __bss, __common): every static of the core, the
 *     dispatcher and the families (rails, handle counter, known flags, violation count, the theta
 *     schedule, rt-bus's cell map, rt-tape's tables, the registered end-of-shot handlers) and the program's
 *     own globals;
 *   - the heap: malloc, calloc, realloc and free of the executable are this file's (below). What the
 *     setup allocates (blocks under SETUP_BIG bytes) lies in the setup arena, whose contents are put
 *     back; what a sample allocates lies in the sample arena, emptied after every sample;
 *   - the __cq_alloc arena (bundle/host/cq_host.c, through its two hooks): the same for program memory;
 *   - the stack above the driver's call (the setup's locals);
 *   - the floating-point environment (fesetenv), and the worker's signal handlers.
 * The end of a shot is the end of a process: the handlers registered with atexit (atexit of the
 * executable is this file's: the core's exit-event handler first, so it runs last, C1) run in reverse
 * order and the core writes the exit event. exit(n) in a sample does the same and ends the sample
 * with status n; _exit(n) and _Exit(n) end it with status n without the handlers (no exit event).
 * A sample that raises a signal (SIGFPE, SIGSEGV, SIGBUS, SIGILL, SIGABRT, SIGTRAP, SIGSYS, SIGALRM)
 * ends with status minus the signal, no exit event, and the worker ends with it: the server forks a
 * fresh worker for the next record. A timeout ends the same way; it is never a matter of wall time,
 * so that no result depends on the machine's load (cq-o4ul): a sample that enters more than
 * $CQE_SHOT_STEPS basic blocks of the lowered module (the step budget, deterministic; below) or uses
 * more than $CQE_SHOT_TIMEOUT seconds of CPU time (default 30, SIGPROF) is a timeout. The server also
 * SIGKILLs a worker that makes no progress (a timeout) while it is blocked (server_wait).
 * Allocation past the sample arena falls back to the system heap; that sample's worker then ends
 * after it. Not put back: state inside the C library (stdio buffers, strtok, rand, locale, errno),
 * blocks the C library allocated, and blocks of SETUP_BIG bytes or more the setup allocated (the
 * driver's sample buffer).
 *
 * Frames, private to chk-core (run.py removes them):
 *   {"ev":"shot","k":<k>}    before a sample's events
 *   {"ev":"shot_end","k":<k>,"code":<c>,"timeout":<0|1>,"stdout":"..","stderr":".."}   after them
 * k = $CQE_SHOT_BASE + the record index; code is the sample's status. stdout is what the sample wrote
 * to stdout, stderr the last 4000 bytes of what it wrote to stderr when code is not 0 (and the trace is
 * not stderr), both byte by byte (every byte >= 0x7f as \u00XX). $CQE_SHOT_DIR is a directory for the
 * capture files (a fresh one under $TMPDIR when unset). $CQE_THETA_ALL holds the theta schedules of
 * the batch: "@<k>" lines in increasing k, each followed by sample k's $CQE_THETA lines; a sample
 * with no block has no schedule. Without $CQE_THETA_ALL every sample reads $CQE_THETA. */

#include <dlfcn.h>
#include <fenv.h>
#include <mach-o/getsect.h>
#include <mach-o/ldsyms.h>
#include <libproc.h>
#include <mach/mach_time.h>
#include <malloc/malloc.h>
#include <pthread.h>
#include <setjmp.h>
#include <sys/mman.h>

void cqe__theta_use(const char *text, size_t n); /* dispatch.c */

/* -- the heap -- */

#define SETUP_ARENA ((size_t)256 << 20)
#define SAMPLE_ARENA ((size_t)2 << 30)
#define SETUP_BIG ((size_t)64 << 10)

typedef struct { char *base, *top, *end; } arena_t;
static arena_t a_setup, a_sample; /* in __DATA: a sample's restore empties a_sample */

typedef struct shot_state shot_state;
static shot_state *R; /* the shared state (mmap); NULL until the first record */

static int in_arena(const arena_t *a, const void *p) { return a->base && (const char *)p >= a->base && (const char *)p < a->end; }

/* The sample arena's free lists (cq-8m6v): a block freed in a sample goes to the list of its size
 * class (16-byte steps up to ARENA_FL_MAX) and the next malloc of that class takes it, zeroed, as a
 * fresh arena block would be. In __DATA, so a sample's restore empties them with the arena. */
#define ARENA_FL_MAX ((size_t)64 << 10)
static void *arena_fl[ARENA_FL_MAX / 16 + 1];

#define ARENA_FREED ((size_t)0xf4eef4eef4eef4eeULL) /* the header's second word of a block on a free list */

static size_t arena_need(size_t n) { return ((n + 15) & ~(size_t)15) + 16; }

static int arena_map(arena_t *a, size_t reserve) {
  if (!a->base) {
    void *m = mmap(NULL, reserve, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (m == MAP_FAILED)
      return 0;
    a->base = a->top = m;
    a->end = a->base + reserve;
  }
  return 1;
}

static void *arena_alloc(arena_t *a, size_t reserve, size_t n) {
  if (a == &a_sample && arena_need(n) >= n && arena_need(n) <= ARENA_FL_MAX) {
    void **head = &arena_fl[arena_need(n) / 16];
    if (*head) {
      char *p = *head;
      *head = *(void **)p;
      memset(p, 0, arena_need(n) - 16);
      *(size_t *)(p - 16) = n;
      *(size_t *)(p - 8) = 0;
      return p;
    }
  }
  if (!a->base) {
    void *m = mmap(NULL, reserve, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (m == MAP_FAILED)
      return NULL;
    a->base = a->top = m;
    a->end = a->base + reserve;
  }
  size_t need = ((n + 15) & ~(size_t)15) + 16;
  if (need < n || (size_t)(a->end - a->top) < need)
    return NULL;
  char *p = a->top;
  a->top += need;
  *(size_t *)p = n;
  return p + 16;
}

static int sample_running(void);
static void shot_mark_dirty(void);

void *malloc(size_t n) {
  void *p = NULL;
  if (sample_running()) {
    p = arena_alloc(&a_sample, SAMPLE_ARENA, n);
    if (!p)
      shot_mark_dirty();
  } else if (n < SETUP_BIG) {
    p = arena_alloc(&a_setup, SETUP_ARENA, n);
  }
  return p ? p : malloc_zone_malloc(malloc_default_zone(), n ? n : 1);
}

void *calloc(size_t n, size_t sz) {
  if (sz && n > (size_t)-1 / sz)
    return NULL;
  void *p = malloc(n * sz);
  if (p)
    memset(p, 0, n * sz);
  return p;
}

void free(void *p) {
  if (in_arena(&a_sample, p)) { /* to its class's free list (above); a large block goes with the arena */
    size_t need = arena_need(*(size_t *)((char *)p - 16));
    size_t *mark = (size_t *)((char *)p - 8);
    if (*mark != ARENA_FREED) { /* a second free of a block changes nothing */
      *mark = ARENA_FREED;   /* a large block is marked too: cell_dead reads the mark (cq-tt2j) */
      if (need <= ARENA_FL_MAX) {
        *(void **)p = arena_fl[need / 16];
        arena_fl[need / 16] = p;
      }
    }
    return;
  }
  if (!p || in_arena(&a_setup, p))
    return; /* an arena block goes with its arena */
  malloc_zone_t *z = malloc_zone_from_ptr(p);
  if (z)
    malloc_zone_free(z, p);
}

void *realloc(void *p, size_t n) {
  if (!p)
    return malloc(n);
  if (in_arena(&a_setup, p) || in_arena(&a_sample, p)) {
    size_t old = *(size_t *)((char *)p - 16);
    void *q = malloc(n);
    if (q) {
      memcpy(q, p, old < n ? old : n);
      free(p); /* a sample block to its free list (cq-8m6v); a setup block stays */
    }
    return q;
  }
  malloc_zone_t *z = malloc_zone_from_ptr(p);
  return malloc_zone_realloc(z ? z : malloc_default_zone(), p, n);
}

/* -- atexit and exit -- */

#define MAX_EXIT_FNS 64
static void (*exit_fns[MAX_EXIT_FNS])(void);
static int nexit_fns;

int atexit(void (*fn)(void)) {
  if (nexit_fns == MAX_EXIT_FNS) {
    fprintf(stderr, "cq: chk-core: more than %d atexit handlers\n", MAX_EXIT_FNS);
    abort();
  }
  exit_fns[nexit_fns++] = fn;
  return 0;
}

void cqe__invert_close_all(void) __attribute__((weak)); /* dispatch.c (cq-4593) */
/* bundle/host/cq_host.c: its __cq_alloc arena; these weak definitions are for a runtime linked without that file */
__attribute__((weak)) void __cq_host_snapshot(void) {}
__attribute__((weak)) void __cq_host_restore(void) {}

static void run_exit_fns(void) {
  if (cqe__invert_close_all)
    cqe__invert_close_all(); /* BACKEND_ABI 1.13: a region still open at the end of the shot is closed */
  while (nexit_fns > 0)
    exit_fns[--nexit_fns]();
}

int __cxa_atexit(void (*)(void *), void *, void *);
typedef void (*exit_fn_t)(int) __attribute__((noreturn));
static exit_fn_t real_exit, real__exit;

/* The C library's exit of a process that is no batch (no record ran): the handlers, as before. */
static void libc_exit_hook(void *unused) {
  (void)unused;
  if (!R)
    run_exit_fns();
}

__attribute__((constructor(100))) static void shot_ctor(void) {
  real_exit = (exit_fn_t)dlsym(RTLD_NEXT, "exit");
  real__exit = (exit_fn_t)dlsym(RTLD_NEXT, "_exit");
  if (!real_exit || !real__exit) {
    fprintf(stderr, "cq: chk-core: no exit/_exit in the C library\n");
    abort();
  }
  __cxa_atexit(libc_exit_hook, NULL, NULL);
}

/* -- the shared state -- */

enum { J_NONE, J_EXIT, J_SIGNAL };

struct shot_state {
  sigjmp_buf jb;          /* the driver's sigsetjmp, in the worker */
  pid_t server, worker;
  long resume;            /* server: the first record not yet run */
  long next;              /* worker: the record after the last one it finished */
  long cur;               /* the record of the running sample */
  volatile long progress; /* worker: bumped at every shot's start and end */
  volatile int in_sample, dirty;
  int jkind, code, ran_fns, timeout;
  long base;
  double timeout_s;
  /* the worker's snapshot (taken at its first sample) */
  int snapped;
  struct { char *at, *copy; size_t n; } sect[3];
  int nsect;
  char *setup_copy;
  size_t setup_n;
  fenv_t fenv;
  char *stack_lo, *stack_copy;
  size_t stack_n, stack_cap;
  int out_fd, err_fd; /* read ends of the capture files */
  long freed_n;           /* the running sample's cqrt_free calls (cq-8m6v), and */
  unsigned long long freed_dig; /* FNV-1a-64 of their handles in order: the shot_end frame's summary */
  int rotate;             /* worker: the trace passed $CQE_TRACE_ROTATE; the runner ends (cq-3fjt) */
};

#define FREED_DIG0 0xcbf29ce484222325ULL

/* cq-tt2j (mark_outputs): p lies in a dead stack frame (below the driver's frame at the sample's
 * start; with no shot running, every stack address) or in a freed block of the sample arena. The
 * sample arena's blocks lie back to back from its base (header: size, free mark), so the block of p
 * is found by walking them; done once per noted cell at exit only. */
static int cell_dead(uintptr_t p) {
  char *hi = (char *)pthread_get_stackaddr_np(pthread_self());
  char *lo = hi - pthread_get_stacksize_np(pthread_self());
  if ((char *)p >= lo && (char *)p < hi)
    return !(sample_running() && (char *)p >= R->stack_lo);
  if (!in_arena(&a_sample, (void *)p) || (char *)p >= a_sample.top)
    return 0;
  for (char *b = a_sample.base; b < a_sample.top;) {
    size_t n = *(size_t *)b;
    char *next = b + arena_need(n);
    if ((char *)p < next)
      return (char *)p >= b + 16 && *(size_t *)(b + 8) == ARENA_FREED;
    b = next;
  }
  return 0;
}

/* A cqrt_free of rail h with its known flag: counted into the running sample's summary; whether its
 * free event is written (always outside a sample and without the compact trace; in a sample of a
 * compact trace only a dirty one, which compare reports). */
int cqe__free_note(int32_t h, int known) {
  if (!sample_running())
    return 1;
  R->freed_n++;
  R->freed_dig = (R->freed_dig ^ (uint32_t)h) * 0x100000001b3ULL;
  return !compact || !known;
}

static char shot_dir[1024], shot_out[1100], shot_err[1100];
static int shot_own_dir;
static char *theta_all; /* $CQE_THETA_ALL's text (system heap: never put back) */
static int theta_all_set;
typedef struct { long k; const char *p; size_t n; } theta_block;
static theta_block *theta_blocks;
static size_t theta_nblocks;

static int sample_running(void) { return R && R->in_sample && getpid() == R->worker; }
static void shot_mark_dirty(void) { R->dirty = 1; }

static void shot_die(const char *what) {
  fprintf(stderr, "cq: chk-core: %s: %s\n", what, strerror(errno));
  real__exit(98);
}

static void *sys_alloc(size_t n) {
  void *p = malloc_zone_malloc(malloc_default_zone(), n ? n : 1);
  if (!p)
    shot_die("out of memory");
  return p;
}

void exit(int code) {
  if (sample_running()) {
    R->jkind = J_EXIT;
    R->code = code & 0xff;
    R->ran_fns = 0;
    siglongjmp(R->jb, 1);
  }
  real_exit(code);
}

__attribute__((noreturn)) static void quick_exit_(int code) {
  if (sample_running()) {
    R->jkind = J_EXIT;
    R->code = code & 0xff;
    R->ran_fns = -1; /* no handlers */
    siglongjmp(R->jb, 1);
  }
  real__exit(code);
}
void _exit(int code) { quick_exit_(code); }
void _Exit(int code) { quick_exit_(code); }

/* -- capture files -- */

/* JSON string body of bytes (heap of the current phase). */
static char *json_bytes(const unsigned char *b, size_t n) {
  char *o = xcalloc(6 * n + 1, 1), *p = o;
  for (size_t i = 0; i < n; ++i) {
    unsigned char c = b[i];
    if (c == '"' || c == '\\') {
      *p++ = '\\';
      *p++ = (char)c;
    } else if (c < 0x20 || c >= 0x7f) {
      p += sprintf(p, "\\u%04x", c);
    } else {
      *p++ = (char)c;
    }
  }
  return o;
}

/* What fd (writing the capture file read through rfd) holds, its last `tail` bytes when tail > 0, as
 * a JSON string body; the file is emptied. */
static char *take_capture(int fd, int rfd, long tail) {
  struct stat st;
  if (fstat(fd, &st) != 0 || st.st_size == 0)
    return xcalloc(1, 1);
  size_t n = (size_t)st.st_size, from = (tail > 0 && n > (size_t)tail) ? n - (size_t)tail : 0;
  unsigned char *b = xcalloc(n - from + 1, 1);
  ssize_t got = pread(rfd, b, n - from, (off_t)from);
  char *o = json_bytes(b, got > 0 ? (size_t)got : 0);
  free(b);
  if (ftruncate(fd, 0) != 0 || lseek(fd, 0, SEEK_SET) < 0)
    shot_die("cannot empty a capture file");
  return o;
}

static void log_shot_end(long k, int code, int timeout, const char *out, const char *err) {
  cqe__logf("{\"ev\":\"shot_end\",\"k\":%ld,\"code\":%d,\"timeout\":%d,\"stdout\":\"%s\",\"stderr\":\"%s\","
            "\"freed\":%ld,\"fdig\":\"0x%llx\"}",
            k, code, timeout, out, err, R->freed_n, R->freed_dig);
}

/* -- theta -- */

/* $CQE_THETA_ALL "-" (cq-8m6v: run.py pipes its batch, no files): the schedules come first on stdin,
 * ended by a line "%%"; the driver reads its records from the rest of stdin (CQD_SAMPLES "-"). Read
 * by a constructor, before the driver's main touches stdin, into the system heap. */
static char *theta_stdin;

__attribute__((constructor(102))) static void theta_stdin_ctor(void) {
  const char *th = getenv("CQE_THETA_ALL");
  if (!th || strcmp(th, "-") != 0)
    return;
  size_t cap = 1 << 16, n = 0, line = 0;
  char *b = malloc_zone_malloc(malloc_default_zone(), cap);
  int c;
  while (b && (c = getc(stdin)) != EOF) {
    if (n + 2 > cap) {
      cap *= 2;
      b = malloc_zone_realloc(malloc_default_zone(), b, cap);
      if (!b)
        break;
    }
    b[n++] = (char)c;
    if (c == '\n') {
      if (n - line == 3 && b[line] == '%' && b[line + 1] == '%') {
        n = line;
        break;
      }
      line = n;
    }
  }
  if (!b) {
    fprintf(stderr, "cq: chk-core: out of memory reading the theta schedules\n");
    abort();
  }
  b[n] = 0;
  theta_stdin = b;
}

static void theta_all_load(const char *path) {
  theta_all_set = 1;
  if (!strcmp(path, "-")) {
    static char none[1];
    theta_all = theta_stdin ? theta_stdin : none;
  } else {
    FILE *f = fopen(path, "rb");
    if (!f)
      shot_die("cannot open $CQE_THETA_ALL");
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    theta_all = sys_alloc((size_t)n + 1);
    if (fread(theta_all, 1, (size_t)n, f) != (size_t)n)
      shot_die("cannot read $CQE_THETA_ALL");
    theta_all[n] = 0;
    fclose(f);
  }
  size_t cap = 0;
  for (char *p = theta_all; *p;) {
    char *nl = strchr(p, '\n');
    char *end = nl ? nl + 1 : p + strlen(p);
    if (*p == '@') {
      if (theta_nblocks == cap) {
        theta_block *nb = sys_alloc((cap ? 2 * cap : 256) * sizeof *nb);
        if (theta_nblocks)
          memcpy(nb, theta_blocks, theta_nblocks * sizeof *nb);
        cap = cap ? 2 * cap : 256;
        theta_blocks = nb; /* the old block is left: a few KB once per batch */
      }
      theta_block *b = &theta_blocks[theta_nblocks++];
      b->k = strtol(p + 1, NULL, 10);
      b->p = end;
      b->n = 0;
    } else if (theta_nblocks) {
      theta_blocks[theta_nblocks - 1].n += (size_t)(end - p);
    }
    p = end;
  }
}

static void theta_for(long k) {
  if (!theta_all_set)
    return;
  size_t lo = 0, hi = theta_nblocks;
  while (lo < hi) {
    size_t mid = (lo + hi) / 2;
    if (theta_blocks[mid].k < k)
      lo = mid + 1;
    else
      hi = mid;
  }
  if (lo < theta_nblocks && theta_blocks[lo].k == k)
    cqe__theta_use(theta_blocks[lo].p, theta_blocks[lo].n);
  else
    cqe__theta_use(NULL, 0);
}

/* -- signals and timers -- */

static const int fatal_sigs[] = {SIGFPE, SIGSEGV, SIGBUS, SIGILL, SIGABRT, SIGTRAP, SIGSYS, SIGALRM, SIGPROF};
#define NFATAL ((int)(sizeof fatal_sigs / sizeof fatal_sigs[0]))

static void timer_set(double s, int periodic) {
  struct itimerval it;
  memset(&it, 0, sizeof it);
  if (s > 0) {
    it.it_value.tv_sec = (time_t)s;
    it.it_value.tv_usec = (suseconds_t)((s - (double)(time_t)s) * 1e6);
    if (!it.it_value.tv_sec && !it.it_value.tv_usec)
      it.it_value.tv_usec = 1;
    if (periodic)
      it.it_interval = it.it_value;
  }
  setitimer(ITIMER_REAL, &it, NULL);
}

/* The worker's per-sample limit: s seconds of its own CPU time (SIGPROF), 0 to stop it. CPU time, not
 * wall time: how long a sample takes on a loaded machine must not decide its result (cq-o4ul). */
static void cpu_timer_set(double s) {
  struct itimerval it;
  memset(&it, 0, sizeof it);
  if (s > 0) {
    it.it_value.tv_sec = (time_t)s;
    it.it_value.tv_usec = (suseconds_t)((s - (double)(time_t)s) * 1e6);
    if (!it.it_value.tv_sec && !it.it_value.tv_usec)
      it.it_value.tv_usec = 1;
  }
  setitimer(ITIMER_PROF, &it, NULL);
}

/* The CPU seconds a process has used; -1 when unknown. */
static double proc_cpu(pid_t pid) {
  struct rusage_info_v2 ri;
  if (proc_pid_rusage(pid, RUSAGE_INFO_V2, (rusage_info_t *)&ri) != 0)
    return -1;
  mach_timebase_info_data_t tb;
  mach_timebase_info(&tb);
  return (double)(ri.ri_user_time + ri.ri_system_time) * tb.numer / tb.denom * 1e-9;
}

/* The step budget (cq-o4ul): run.py instruments every basic block of the lowered module with a call
 * of __sanitizer_cov_trace_pc (LLVM's SanitizerCoverage, trace-pc), and a sample that enters more
 * than $CQE_SHOT_STEPS blocks is a timeout, whatever the machine's load. 0 or unset: no budget. */
static unsigned long long shot_steps, shot_step_cap = ~0ULL;

__attribute__((noinline)) static void shot_over_budget(void) {
  if (!sample_running()) { /* the setup has no budget */
    shot_steps = 0;
    return;
  }
  cpu_timer_set(0);
  R->jkind = J_SIGNAL;
  R->code = -SIGALRM;
  R->timeout = 1;
  siglongjmp(R->jb, 1);
}

static void shot_output_check(void);

void __sanitizer_cov_trace_pc(void) {
  if (++shot_steps > shot_step_cap)
    shot_over_budget();
  if (!(shot_steps & 0xffff))
    shot_output_check();
}

/* A running sample past a disk cap (cq-3fjt, the trace section): a "trace_cap" violation, and the
 * sample ends as by signal SIGXFSZ (its worker with it). Outside a sample: nothing (the setup's own
 * output has only the RLIMIT_FSIZE backstop). */
static void shot_over(const char *what, unsigned long long cap) {
  if (!sample_running() || R->jkind == J_SIGNAL)
    return;
  cpu_timer_set(0);
  R->jkind = J_SIGNAL; /* before the violation below: its own line does not come back here */
  R->code = -SIGXFSZ;
  R->timeout = 0;
  shot_trace_cap = ~0ULL;
  cqe__violation("trace_cap", -1, "cq-3fjt: the sample's %s passed %llu bytes; the sample ends here", what, cap);
  fprintf(stderr, "cq: chk-core: the sample's %s passed %llu bytes (cq-3fjt disk cap)\n", what, cap);
  fflush(stderr);
  siglongjmp(R->jb, 1);
}

/* A running sample past the violation cap: a "violation_cap" violation, and the sample ends as at a
 * disk cap (SIGXFSZ, its worker with it). Outside a sample: nothing (the setup is not capped). */
static void shot_over_violations(void) {
  if (!sample_running() || R->jkind == J_SIGNAL)
    return;
  cpu_timer_set(0);
  R->jkind = J_SIGNAL; /* before the violation below: its own line does not come back here */
  R->code = -SIGXFSZ;
  R->timeout = 0;
  unsigned long long cap = shot_viol_cap;
  shot_viol_cap = ~0ULL;
  cqe__violation("violation_cap", -1, "cq-r8-chk176: the sample logged more than %llu violations; the sample ends here",
                 cap);
  siglongjmp(R->jb, 1);
}

static void shot_output_check(void) {
  if (!sample_running())
    return;
  struct stat st;
  if (fstat(1, &st) == 0 && (unsigned long long)st.st_size > shot_output_cap)
    shot_over("stdout", shot_output_cap);
  if (R->err_fd >= 0 && fstat(2, &st) == 0 && (unsigned long long)st.st_size > shot_output_cap)
    shot_over("stderr", shot_output_cap);
}

static void worker_on_signal(int sig) {
  if (!sample_running()) {
    signal(sig, SIG_DFL);
    raise(sig);
    return;
  }
  R->jkind = J_SIGNAL;
  R->code = -sig;
  R->timeout = sig == SIGPROF;
  siglongjmp(R->jb, 1);
}

static void worker_signals(void) {
  struct sigaction sa;
  memset(&sa, 0, sizeof sa);
  sa.sa_handler = worker_on_signal;
  sa.sa_flags = SA_ONSTACK | SA_NODEFER;
  sigemptyset(&sa.sa_mask);
  for (int i = 0; i < NFATAL; ++i)
    sigaction(fatal_sigs[i], &sa, NULL);
}

static volatile sig_atomic_t server_tick;
static void server_on_alarm(int sig) {
  (void)sig;
  server_tick = 1;
}

/* -- the worker's snapshot -- */

static void snapshot_take(void) {
  static const char *names[] = {"__data", "__bss", "__common"};
  /* cq-8m6v: map the sample arena now, so that the snapshot holds its base and every restore empties
   * it (top = base) instead of forgetting it: a sample used to map a fresh 2 GB arena and leave the
   * last one's pages resident, so a runner grew with its batch */
  if (!arena_map(&a_sample, SAMPLE_ARENA))
    shot_die("mmap of the sample arena");
  R->nsect = 0;
  for (int i = 0; i < 3; ++i) {
    unsigned long n = 0;
    uint8_t *at = getsectiondata(&_mh_execute_header, "__DATA", names[i], &n);
    if (!at || !n)
      continue;
    R->sect[R->nsect].at = (char *)at;
    R->sect[R->nsect].n = n;
    R->sect[R->nsect].copy = sys_alloc(n);
    R->nsect++;
  }
  R->setup_n = a_setup.base ? (size_t)(a_setup.top - a_setup.base) : 0;
  R->setup_copy = sys_alloc(R->setup_n);
  if (R->setup_n)
    memcpy(R->setup_copy, a_setup.base, R->setup_n);
  fegetenv(&R->fenv);
  __cq_host_snapshot();
  /* every flag the worker sets is set before this copy, so the copy keeps it */
  for (int i = 0; i < R->nsect; ++i)
    memcpy(R->sect[i].copy, R->sect[i].at, R->sect[i].n);
  R->snapped = 1;
}

/* The pages the sample used, replaced by fresh zero pages (cq-8m6v): the next sample's blocks read 0
 * until written, as blocks of a fresh arena did, and the memory goes back to the system. */
static void arena_recycle(void) {
  if (!a_sample.base || a_sample.top <= a_sample.base)
    return;
  size_t pg = (size_t)getpagesize();
  size_t n = ((size_t)(a_sample.top - a_sample.base) + pg - 1) & ~(pg - 1);
  if (mmap(a_sample.base, n, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON | MAP_FIXED, -1, 0) == MAP_FAILED)
    shot_die("mmap of the sample arena");
}

static void snapshot_restore(void) {
  __cq_host_restore(); /* reads the sample's own statics: before __DATA is put back */
  for (int i = 0; i < R->nsect; ++i)
    memcpy(R->sect[i].at, R->sect[i].copy, R->sect[i].n);
  if (R->setup_n)
    memcpy(a_setup.base, R->setup_copy, R->setup_n);
  fesetenv(&R->fenv);
}

/* The stack from the driver's frame up: the setup's locals. Saved at every sample's start. */
static void stack_save(char *lo) {
  char *hi = (char *)pthread_get_stackaddr_np(pthread_self());
  if (!(lo < hi))
    shot_die("stack bounds");
  R->stack_lo = lo;
  R->stack_n = (size_t)(hi - lo);
  if (R->stack_n > R->stack_cap) {
    R->stack_copy = sys_alloc(R->stack_n);
    R->stack_cap = R->stack_n;
  }
  /* the copy is a block of this worker's own heap: one an earlier worker allocated lies in memory this
   * worker may hand to anything (malloc zones are per CPU, so whether it does depends on load) and
   * would be put back over the stack (cq-o4ul) */
  if (malloc_size(R->stack_copy) < R->stack_n) {
    fprintf(stderr, "cq: chk-core: the stack copy is no block of this worker's heap\n");
    real__exit(98);
  }
  memcpy(R->stack_copy, lo, R->stack_n);
}

__attribute__((noinline)) static void stack_restore(void) {
  char *here = (char *)__builtin_frame_address(0);
  if (here + 64 > R->stack_lo) {
    fprintf(stderr, "cq: chk-core: the driver's frame moved between a sample's start and end\n");
    real__exit(98);
  }
  memcpy(R->stack_lo, R->stack_copy, R->stack_n);
}

/* -- the server -- */

static void server_setup(void) {
  void *m = mmap(NULL, sizeof(shot_state), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
  if (m == MAP_FAILED)
    shot_die("mmap");
  R = m;
  memset(R, 0, sizeof *R);
  R->server = getpid();
  const char *d = getenv("CQE_SHOT_DIR");
  if (d && *d) {
    snprintf(shot_dir, sizeof shot_dir, "%s", d);
  } else {
    const char *t = getenv("TMPDIR");
    snprintf(shot_dir, sizeof shot_dir, "%s/cqe-shot.XXXXXX", t && *t ? t : "/tmp");
    if (!mkdtemp(shot_dir))
      shot_die("mkdtemp");
    shot_own_dir = 1;
  }
  snprintf(shot_out, sizeof shot_out, "%s/out", shot_dir);
  snprintf(shot_err, sizeof shot_err, "%s/err", shot_dir);
  const char *b = getenv("CQE_SHOT_BASE");
  R->base = b && *b ? strtol(b, NULL, 10) : 0;
  const char *to = getenv("CQE_SHOT_TIMEOUT");
  R->timeout_s = to && *to ? strtod(to, NULL) : 30.0;
  const char *steps = getenv("CQE_SHOT_STEPS");
  unsigned long long cap = steps && *steps ? strtoull(steps, NULL, 10) : 0;
  shot_step_cap = cap ? cap : ~0ULL;
  const char *th = getenv("CQE_THETA_ALL");
  if (th && *th)
    theta_all_load(th);
  shot_muted = 1; /* the server logs only frames of samples its worker could not end */
  struct sigaction sa;
  memset(&sa, 0, sizeof sa);
  sa.sa_handler = server_on_alarm; /* no SA_RESTART: waitpid returns EINTR */
  sigemptyset(&sa.sa_mask);
  sigaction(SIGALRM, &sa, NULL);
}

static void server_cleanup(void *unused) {
  (void)unused;
  if (R && getpid() == R->server && shot_own_dir) {
    unlink(shot_out);
    unlink(shot_err);
    rmdir(shot_dir);
  }
}

static int open_capture(const char *path, int fd) {
  int w = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
  if (w < 0 || dup2(w, fd) < 0)
    shot_die("cannot open a capture file");
  close(w);
  int r = open(path, O_RDONLY);
  if (r < 0)
    shot_die("cannot open a capture file");
  return r;
}

static void worker_start(void) {
  R->worker = getpid();
  /* R outlives a worker; a block an earlier worker allocated is not this worker's (cq-o4ul) */
  R->snapped = 0;
  R->stack_copy = NULL;
  R->stack_cap = 0;
  R->dirty = 0;
  R->in_sample = 0;
  shot_muted = 0;
  shot_buffered = 1;
  signal(SIGALRM, SIG_DFL);
  timer_set(0, 0);
  cpu_timer_set(0);
  R->out_fd = open_capture(shot_out, 1);
  R->err_fd = trace_f != stderr ? open_capture(shot_err, 2) : -1;
  stack_t ss = {.ss_sp = sys_alloc(1 << 16), .ss_size = 1 << 16, .ss_flags = 0}; /* a stack overflow still reaches the handler */
  sigaltstack(&ss, NULL);
}

/* The server's wait for its worker; the record to resume at afterwards. */
static void server_wait(void) {
  long first = R->next; /* the record the worker starts at */
  long last = -1;
  int killed = 0;
  double limit = 2 * R->timeout_s + 1, cpu_last = -1, cpu_mark = 0;
  server_tick = 0;
  timer_set(limit, 1);
  int st = 0;
  for (;;) {
    pid_t r = waitpid(R->worker, &st, 0);
    if (r == R->worker)
      break;
    if (r < 0 && errno == EINTR) {
      if (server_tick) {
        server_tick = 0;
        /* A worker that made no progress over a whole tick is killed (a timeout) when it used no CPU
         * in it (blocked, e.g. in a read), or more than `limit` CPU seconds since its last progress
         * (SIGPROF blocked). Never for wall time alone: a worker the machine's load slows down still
         * uses CPU, and its samples end as they would on an idle machine (cq-o4ul). */
        double cpu = proc_cpu(R->worker);
        if (R->progress != last) {
          last = R->progress;
          cpu_mark = cpu;
        } else if (!killed && (cpu < 0 || cpu == cpu_last || cpu - cpu_mark > limit)) {
          kill(R->worker, SIGKILL);
          killed = 1;
        }
        cpu_last = cpu;
      }
      continue;
    }
    shot_die("waitpid");
  }
  timer_set(0, 0);
  if (!R->in_sample && R->next == first) {
    /* the worker ended before it finished a record: a fresh one would end the same way (cq-o4ul) */
    char tail[2001] = "";
    int efd = trace_f != stderr ? open(shot_err, O_RDONLY) : -1;
    if (efd >= 0) {
      off_t n = lseek(efd, 0, SEEK_END), from = n > 2000 ? n - 2000 : 0;
      ssize_t got = pread(efd, tail, (size_t)(n - from), from);
      tail[got > 0 ? got : 0] = 0;
      close(efd);
    }
    fprintf(stderr, "cq: chk-core: the worker ended (status %d) before it finished a record: %s\n", st, tail);
    real__exit(98);
  }
  if (!R->in_sample) {
    R->resume = R->next;
    if (R->rotate) { /* cq-3fjt: run.py runs the rest in a fresh runner, with a fresh trace */
      fflush(NULL);
      fprintf(stderr, "cq: chk-core: trace rotation before record %ld\n", R->next);
      real__exit(99);
    }
    return;
  }
  /* the worker ended inside a sample: a signal it caught (J_SIGNAL), or a kill */
  int code, timeout;
  if (R->jkind == J_SIGNAL && !killed) {
    code = R->code;
    timeout = R->timeout;
  } else {
    code = WIFSIGNALED(st) ? -WTERMSIG(st) : WIFEXITED(st) ? WEXITSTATUS(st) : -1;
    timeout = killed;
  }
  int ofd = open(shot_out, O_RDWR), efd = trace_f != stderr ? open(shot_err, O_RDWR) : -1;
  /* a sample past a disk cap (SIGXFSZ) failed already; its stdout is not read back (cq-3fjt) */
  char *out = ofd >= 0 && code != -SIGXFSZ ? take_capture(ofd, ofd, 0) : xcalloc(1, 1);
  char *err = (efd >= 0 && code) ? take_capture(efd, efd, 4000) : xcalloc(1, 1);
  if (ofd >= 0)
    close(ofd);
  if (efd >= 0)
    close(efd);
  shot_muted = 0;
  log_shot_end(R->base + R->cur, code, timeout, out, err);
  fflush(trace_f);
  shot_muted = 1;
  free(out);
  free(err);
  R->in_sample = 0;
  R->resume = R->cur + 1;
}

/* -- the driver's hooks -- */

/* The driver's jump target; the first call (the first record's) makes this process the server. */
sigjmp_buf *cqe__shot_jb(void) {
  cqe__init();
  if (!R) {
    fflush(NULL);
    server_setup();
    __cxa_atexit(server_cleanup, NULL, NULL);
  }
  return &R->jb;
}

static void shot_finish(int code, int run_fns);

/* before_call: 1 in the worker (run the sample), 0 in the server (skip the record). */
int cqe__shot_enter(int idx) {
  if (!R) {
    fprintf(stderr, "cq: chk-core: cqe__shot_enter before cqe__shot_jb\n");
    abort();
  }
  if (getpid() == R->server) {
    if (idx < R->resume)
      return 0;
    R->next = idx;
    fflush(NULL);
    pid_t pid = fork();
    if (pid < 0)
      shot_die("fork");
    if (pid > 0) {
      R->worker = pid;
      server_wait();
      return 0;
    }
    worker_start();
  }
  /* the worker: a sample */
  if (!R->snapped)
    snapshot_take();
  worker_signals(); /* every sample: the program may have replaced a handler */
  long k = R->base + idx;
  cqe__logf("{\"ev\":\"shot\",\"k\":%ld}", k);
  theta_for(k);
  stack_save((char *)__builtin_frame_address(0) + 16);
  R->cur = idx;
  R->freed_n = 0;
  R->freed_dig = FREED_DIG0;
  R->jkind = J_NONE;
  R->progress++;
  shot_steps = 0;
  shot_trace_n = 0;
  shot_viol_n = 0;
  R->in_sample = 1;
  cpu_timer_set(R->timeout_s);
  return 1;
}

static void shot_finish(int code, int run_fns) {
  cpu_timer_set(0);
  if (run_fns)
    run_exit_fns();
  fflush(stdout);
  fflush(stderr);
  shot_output_check();
  char *out = take_capture(1, R->out_fd, 0);
  char *err = R->err_fd >= 0 ? (code ? take_capture(2, R->err_fd, 4000) : (take_capture(2, R->err_fd, 1), xcalloc(1, 1)))
                             : xcalloc(1, 1);
  log_shot_end(R->base + R->cur, code, 0, out, err);
  fflush(trace_f);
  R->next = R->cur + 1; /* before in_sample drops: the server never runs a finished sample again */
  R->in_sample = 0;
  R->progress++;
  struct stat ts;
  if (trace_f != stderr && fstat(fileno(trace_f), &ts) == 0 && (unsigned long long)ts.st_size > trace_rotate) {
    R->rotate = 1; /* cq-3fjt: the server ends the runner (server_wait) */
    real__exit(0);
  }
  if (R->dirty) /* the sample left state the snapshot does not cover: a fresh worker goes on */
    real__exit(0);
  stack_restore();
  arena_recycle();
  snapshot_restore();
}

/* after_call: the sample returned. */
void cqe__shot_end(void) { shot_finish(0, 1); }

/* The driver's sigsetjmp returned again: the sample called exit/_exit, or raised a signal. */
void cqe__shot_resume(void) {
  if (R->jkind == J_EXIT) {
    shot_finish(R->code, R->ran_fns == 0);
    return;
  }
  /* a signal: the C library may be inside a lock; leave the end to the server */
  cpu_timer_set(0);
  if (ftrylockfile(trace_f) == 0) {
    fflush(trace_f);
    funlockfile(trace_f);
  }
  if (ftrylockfile(stdout) == 0) {
    fflush(stdout);
    funlockfile(stdout);
  }
  real__exit(0);
}
