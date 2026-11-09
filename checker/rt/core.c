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
 * and not freed, rule 5), a_K (rule 14's kept overflow predicate, marked by run.kept_ak_module, cq-1leyz), n>K2 (rule 20's kept overflow
 * predicate of a rail-sized allocation, marked by run.kept_k2_module, cq-0ldab), frozen (rotated, not measured, or a rule-6 image carrying a rotated register's
 * content: cqe__carry, cq-qhow), rule6_image (an operand of a rule-6 clean's inverse its producer's _unc can no longer
 * clean, frozen or not: cqe__r6_unc, cq-o9mx, cq-cuu82), store_kept (a value or control rail of a bus store still live, rule 5
 * sentence 3), kept_entangled (cq-arch A4: a rail one of whose direct sources received
 * a non-diagonal gate or a measurement after the rail was written), fenv_mode (a rail an _rmq template took as its
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

#include "libm_next.h"
#include <sys/wait.h>
#include <unistd.h>

#include "cqe.h"
#include "rt_replay.h"

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
/* cq-kcn5i (rt_replay.c): a clone replay window is open; anything written to the trace or any violation in it means the
 * window's run cannot be recorded */
int cqe__rp_window, cqe__rp_dirty;
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
 * reach the trace (rotations, measure, ret, violation, exit, effect, the shot frames, rt-bus's out_mem
 * events, rt-tape's end-of-shot events, and the free events of the setup and the dirty ones of a sample);
 * a sample's frees are summed up in its shot_end frame (cqe__free_note), and the exit event's live list
 * comes in runs (at_exit_handler). Without it every event is written, as before. rt-bus's bus and cells
 * events are not in a compact trace (cq-9hzgh): run.py's only reader of the trace (_stream_shots) skipped
 * them unread. */
static int compact;

static int keep_event(const char *s) {
  static const char pre[] = "{\"ev\":\"";
  if (!compact || strncmp(s, pre, sizeof pre - 1) != 0)
    return 1;
  const char *n = s + sizeof pre - 1;
  static const char *keep[] = {"ry\"", "ry_qangle\"", "phase\"", "phase_qangle\"", "measure\"", "ret\"",
                               "violation\"", "exit\"", "host_end\"", "effect\"", "shot\"", "shot_end\"", "free\"",
                               "out_mem\"", "tape\",\"op\":\"shot\""};
  for (size_t i = 0; i < sizeof keep / sizeof *keep; ++i)
    if (!strncmp(n, keep[i], strlen(keep[i])))
      return 1;
  return 0;
}

/* cq-9hzgh: 1 when an event outside the compact set above reaches the trace (no compact trace, not muted).
 * A writer of such an event (gate, tmpl, unc, alloc, push, pop, standin, bus, cells, tape bookkeeping)
 * builds it only then: in a compact trace it would be formatted and dropped. */
void cqe__init(void);
int cqe__trace_all(void) {
  cqe__init();
  return !compact && !shot_muted;
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
  if (cqe__rp_window)
    cqe__rp_dirty = 1;
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
  if (cqe__rp_window)
    cqe__rp_dirty = 1;
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
  if (cqe__rp_window)
    cqe__rp_dirty = 1;
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

/* What few rails need (cq-9hzgh): kept out of rail_t, made at the first use. */
typedef struct {
  int32_t *r6_ops;   /* the old rail of a rule-6 clean whose t's _unc ran first: t's operands, till its free */
  uint32_t r6_nops;
  int32_t r6_old;    /* cq-o9mx: the inverse t of a rule-6 clean: the dead rail its copy left at known |0> */
  uint64_t t_nd, t_meas;  /* event clock of the last non-diagonal gate and of the measurement; 0 = never */
  uint64_t ry_t, ry_ang;  /* cq-3o3v: the last firing Ry on the rail (clock after it, angle bits) */
  uint64_t *ry_pre, *ry_post; /* its target's value before and after it (v.nw words each) */
} rail_ext;

/* What a rail with an extension or a source list that does not fit the record has (rail_t.aux). */
typedef struct {
  rail_ext *ext;
  int32_t *deps; /* the sources: deps_cap(ndeps) entries, NULL while there are none */
  uint32_t ndeps;
} rail_aux;

/* A rail's record (cq-ism39: 72 bytes, was 120; 2026-11-09 memory plan: 32). Its width token is interned (wtab: the
 * width, kind and word count are the token's); the clocks are 48 bits (cqe__tick), the flags are bits. */
typedef struct {
  uint64_t t_create : 48;  /* event clock; 0 = never */
  uint64_t wi : 12;        /* the width token: wtab[wi] */
  uint64_t live : 1;
  uint64_t aux : 1;        /* d.x is in use, else d.in */
  uint64_t : 2;
  uint64_t t_write : 48;   /* event clock; 0 = never */
  uint64_t known : 1, measured : 1, frozen : 1, written : 1, seed : 1;
  uint64_t busz : 1;       /* a bus swap left it at 0 and nothing wrote it since (cqe__set_busz) */
  uint64_t store_kept : 1; /* the value or control rail of a bus store (rule 5 sentence 3) */
  uint64_t image : 1;      /* cq-qhow: carries a frozen register's content (cqe__carry): a rule-6 image, FROZEN */
  uint64_t r6 : 1;         /* cq-o9mx: an operand a rule-6 clean's inverse read: a rule-6 image, kept (cqe__r6_unc) */
  uint64_t load_copy : 1;  /* a bus load's copy: rule 5, "A load copy is never cleaned by rule 6", so never an image */
  uint64_t role : 3;       /* 0 none, 1 abort, 2 tape, 4 tape_slot, 5 overtaken, 6 a_K (cq-1leyz), 7 n>K2 (cq-0ldab) */
  uint64_t fenv : 2;       /* cq-tt2j, rule 23: 1 flags lineage (an _exc result or written from one), 2 a mode operand */
  uint64_t : 1;
  union {
    uint64_t inl;   /* cq-9hzgh: the value of a rail of 64 bits or fewer (rail_w); the pool's free list link */
    uint64_t *wide; /* a wider one's words, allocated */
  } val;
  union {
    int32_t in[2]; /* !aux: up to two sources, none 0, the rest of in 0 */
    rail_aux *x;   /* aux: the extension and the source list */
  } d;
} rail_t;
_Static_assert(sizeof(rail_t) == 32, "rail_t: 32 bytes (2026-11-09 memory plan)");

#define CQE_RAIL_LIMIT 0x51000000u /* rail handles stay below the bus handle (rt_bus.c) */

/* The rail store (cq-ism39). Handles are never reused (cqe.h C1; use_after_free and compare's rails across
 * samples read them), but a record is: a handle maps to a record in the pool while the rail is live, and a
 * freed rail's record goes back to the pool once its content fits a 16-byte tombstone exactly (tomb_fits):
 * value 0 in one word, no extension in use, no sources (cqe__free drops them). Everything a record holds
 * after its free is in the tombstone (its width, flags and two clocks; the rest is 0), so reading a freed rail
 * reads what it held: the cheap readers (cqe__check, the flag getters, a live rail's role, rule 6's marks)
 * read the tombstone, and anything that needs the record (a freed handle used after the use_after_free
 * violation, a cq_invert replay's read of a freed out rail) gets it rebuilt from the tombstone
 * (rail_materialize). Every block stays below SETUP_BIG (a sample's restore puts the setup arena back), and
 * the directories' top levels are static. */
typedef struct { uint64_t a, b; } tomb_t; /* a: t_create | wi << 48; b: t_write | flags << 48 */
#define TOMB_CLOCK_MAX ((1ULL << 48) - 1)
#define MAP_TOMB 0x80000000u /* map entry: the tombstone index | MAP_TOMB, or the pool slot + 1 */

#define LEAF_BITS 12 /* directory blocks: 4096 pointers */
#define MAP_BITS 12  /* a map leaf: 4096 real handles (16 KiB) */
#define POOL_BITS 9  /* a pool leaf: 512 records (36 KiB) */
#define TOMB_BITS 11 /* a tombstone leaf: 2048 (32 KiB) */
#define SIDE_BITS 10 /* a side-table leaf: 1024 entries (12 KiB) */
#define SIDE_HEAD_BITS 14
#define SIDE_HEADS (1u << SIDE_HEAD_BITS)
/* The map (cq-ism39, 2026-11-09 memory plan): a real handle's entry (one cqe__new made) lies in map_dir at the
 * handle's rank among the real handles (hclass), so a replayed call's handles (a block, below) take no map space.
 * A block rail something touched, and a handle that names no rail (rail_blank), has its entry in the side table: a
 * hash of chains through side_dir's nodes (each block of either stays below SETUP_BIG). */
static uint32_t **map_dir[(CQE_RAIL_LIMIT >> (MAP_BITS + LEAF_BITS)) + 1];
typedef struct { uint32_t h, m, next; } side_node;
static side_node **side_dir[(CQE_RAIL_LIMIT >> (SIDE_BITS + LEAF_BITS)) + 2];
static uint32_t side_head[SIDE_HEADS]; /* node index + 1, 0 none */
static uint32_t side_n;
static rail_t **pool_dir[(CQE_RAIL_LIMIT >> (POOL_BITS + LEAF_BITS)) + 1];
static tomb_t **tomb_dir[(CQE_RAIL_LIMIT >> (TOMB_BITS + LEAF_BITS)) + 1];
static uint32_t pool_n, pool_free; /* records made; the free list's head (slot + 1, 0 none), linked through inl */
static uint32_t tomb_n;
static uint32_t nrails;
static uint64_t clock_;

#define DIR_AT(dir, i, bits) (&(dir)[(uint32_t)(i) >> ((bits) + LEAF_BITS)][((uint32_t)(i) >> (bits)) & ((1u << LEAF_BITS) - 1)] \
                                    [(uint32_t)(i) & ((1u << (bits)) - 1)])
#define MAP(d) DIR_AT(map_dir, d, MAP_BITS) /* d: a real handle's dense index (hclass) */
#define SIDE(i) DIR_AT(side_dir, i, SIDE_BITS)
#define SLOT(s) DIR_AT(pool_dir, s, POOL_BITS)
#define TOMB(t) DIR_AT(tomb_dir, t, TOMB_BITS)

/* The leaf of entry i in dir, made when new. */
#define DIR_GROW(dir, i, bits)                                                                          \
  do {                                                                                                  \
    void ***d_ = (void ***)&(dir)[(uint32_t)(i) >> ((bits) + LEAF_BITS)];                               \
    if (!*d_)                                                                                           \
      *d_ = xcalloc((size_t)1 << LEAF_BITS, sizeof **d_);                                               \
    void **c_ = &(*d_)[((uint32_t)(i) >> (bits)) & ((1u << LEAF_BITS) - 1)];                           \
    if (!*c_)                                                                                           \
      *c_ = xcalloc((size_t)1 << (bits), sizeof *(dir)[0][0]);                                          \
  } while (0)

/* Width tokens, interned: a record holds the index. */
#define WTAB_MAX 4096 /* rail_t.wi: 12 bits */
static char wtab[WTAB_MAX][8];
static uint32_t w_bits[WTAB_MAX], w_nw[WTAB_MAX]; /* per token: a value's bits and words (0 for wtab[0]) */
static char w_kind[WTAB_MAX];
static uint32_t wtab_n = 1; /* wtab[0] is "", the width of a blank record (rail_blank): no value */
static uint16_t w_intern(const char *w, uint32_t bits, char kind) {
  char k[8] = {0};
  memcpy(k, w, strnlen(w, sizeof k - 1));
  for (uint32_t i = 1; i < wtab_n; ++i)
    if (!memcmp(wtab[i], k, sizeof k) && w_bits[i] == bits && w_kind[i] == kind)
      return (uint16_t)i;
  if (wtab_n == WTAB_MAX) {
    fprintf(stderr, "cq: chk-core: more than %d rail width tokens\n", WTAB_MAX);
    abort();
  }
  memcpy(wtab[wtab_n], k, sizeof k);
  w_bits[wtab_n] = bits;
  w_kind[wtab_n] = kind;
  w_nw[wtab_n] = cqe__nwords(bits);
  return (uint16_t)wtab_n++;
}

/* A rail's value words (NULL for a blank record), and its value as a cqe_val over them. */
static inline uint64_t *rail_w(rail_t *r) {
  uint32_t nw = w_nw[r->wi];
  return nw > 1 ? r->val.wide : nw ? &r->val.inl : NULL;
}
static inline uint32_t rail_nw(const rail_t *r) { return w_nw[r->wi]; }
static inline cqe_val rail_v(rail_t *r) { return (cqe_val){w_bits[r->wi], w_kind[r->wi], w_nw[r->wi], rail_w(r)}; }

static uint32_t tomb_flags(const rail_t *r) {
  return (uint32_t)r->known | (uint32_t)r->measured << 1 | (uint32_t)r->frozen << 2 | (uint32_t)r->written << 3 |
         (uint32_t)r->seed << 4 | (uint32_t)r->busz << 5 | (uint32_t)r->store_kept << 6 | (uint32_t)r->image << 7 |
         (uint32_t)r->r6 << 8 | (uint32_t)r->load_copy << 9 | (uint32_t)r->role << 10 | (uint32_t)r->fenv << 13;
}
#define TF_KNOWN 0
#define TF_MEASURED 1
#define TF_FROZEN 2
#define TF_BUSZ 5
#define TF_STORE_KEPT 6
#define TF_IMAGE 7
#define TF_R6 8
#define TF_LOAD_COPY 9
#define TF_ROLE 10
#define TF_FENV 13
static inline uint32_t tf_get(const tomb_t *t) { return (uint32_t)(t->b >> 48); }
static inline void tf_set(tomb_t *t, uint32_t f) { t->b = (t->b & TOMB_CLOCK_MAX) | (uint64_t)(f & 0xffff) << 48; }
static inline int tf_bit(const tomb_t *t, int b) { return (int)(tf_get(t) >> b) & 1; }

/* A record from the pool, zeroed; *slot its index. */
static rail_t *pool_take(uint32_t *slot) {
  uint32_t s;
  if (pool_free) {
    s = pool_free - 1;
    pool_free = (uint32_t)(*SLOT(s)).val.inl;
  } else {
    s = pool_n++;
    DIR_GROW(pool_dir, s, POOL_BITS);
  }
  rail_t *r = &(*SLOT(s));
  memset(r, 0, sizeof *r);
  *slot = s;
  return r;
}

static uint32_t map_peek(uint32_t h);
static void map_put(uint32_t h, uint32_t m);

/* The record of tombstoned rail h, rebuilt (and kept: h maps to it from now on). */
static rail_t *rail_materialize(uint32_t h) {
  tomb_t t = (*TOMB(map_peek(h) & ~MAP_TOMB));
  uint32_t s;
  rail_t *r = pool_take(&s);
  uint32_t f = tf_get(&t);
  r->wi = (uint16_t)(t.a >> 48); /* a tombstone's value is one word, 0 */
  r->t_create = t.a & TOMB_CLOCK_MAX;
  r->t_write = t.b & TOMB_CLOCK_MAX;
  r->known = f >> TF_KNOWN & 1;
  r->measured = f >> TF_MEASURED & 1;
  r->frozen = f >> TF_FROZEN & 1;
  r->written = f >> 3 & 1;
  r->seed = f >> 4 & 1;
  r->busz = f >> TF_BUSZ & 1;
  r->store_kept = f >> TF_STORE_KEPT & 1;
  r->image = f >> TF_IMAGE & 1;
  r->r6 = f >> TF_R6 & 1;
  r->load_copy = f >> TF_LOAD_COPY & 1;
  r->role = f >> TF_ROLE & 7;
  r->fenv = f >> TF_FENV & 3;
  map_put(h, s + 1);
  return r;
}

/* A record for a handle in a map leaf that names no rail (handle 0, or one not made yet): all zero, its own,
 * as such a handle's record was in the rail table before (a reader that does not check the handle, CR §1.1's
 * "no rail" 0 among them, reads zeros); cqe__new gives a handle made later a fresh one. */
static rail_t *rail_blank(uint32_t h) {
  uint32_t s;
  rail_t *r = pool_take(&s);
  map_put(h, s + 1);
  return r;
}

/* ---- clone replay (cq-kcn5i, rt_replay.c): the rail store's part ---------------------------------------------
 * Watch. While a window records, a handle at or below its base that is not one of the call's handle arguments is
 * outside the clone's reach: touching it (any read or write through the map) makes the window dirty.
 * Blocks. A replayed call adds one block (its base, the window's record, its clock start, its handle arguments) and
 * advances the handle counter and the event clock; its rails have no map entry until touched, when the block's
 * record makes the rail (rp_materialize) exactly as the real run left it. The exit event reads an untouched block rail
 * from the record without making it. */
static int rp_watch;
static uint32_t rp_wbase;
static const int32_t *rp_wargs;
static int rp_wnargs;
typedef struct {
  uint32_t base, n;
  uint32_t below; /* the handles of the blocks before it (hclass) */
  uint32_t args;  /* its handle arguments: rp_argpool + args (RP_ARGS) */
  uint64_t c0;
  const cqe_rp_rails *rr;
} rp_block;
_Static_assert(sizeof(rp_block) == 32, "rp_block: 32 bytes");
static rp_block *rp_blocks;
static size_t rp_nblocks, rp_capblocks;
static int32_t *rp_argpool; /* every block's handle arguments, one after another */
static size_t rp_nargpool, rp_capargpool;
#define RP_ARGS(b) (rp_argpool + (b)->args)
static size_t rp_hint; /* the block hclass found last */
static uint64_t rp_nmat; /* block rails made since the sample began */

static void rp_outside(uint32_t h) {
  for (int i = 0; i < rp_wnargs; ++i)
    if ((uint32_t)rp_wargs[i] == h)
      return;
  cqe__rp_dirty = 1;
}

/* Where handle h lies: 1 a real handle, *d its dense index (its rank among the real handles, from 1); 2 a rail of
 * block *b; 0 neither (handle 0, or one not made yet). */
static inline int hclass(uint32_t h, uint32_t *d, const rp_block **b) {
  if (!h || h > nrails)
    return 0;
  if (!rp_nblocks) {
    *d = h;
    return 1;
  }
  const rp_block *last = &rp_blocks[rp_nblocks - 1];
  if (h > last->base + last->n) {
    *d = h - last->below - last->n;
    return 1;
  }
  size_t i = rp_hint;
  if (!(i < rp_nblocks && rp_blocks[i].base < h && (i + 1 == rp_nblocks || rp_blocks[i + 1].base >= h))) {
    size_t lo = 0, hi = rp_nblocks;
    while (lo < hi) { /* the first block whose base is >= h */
      size_t mid = (lo + hi) / 2;
      if (rp_blocks[mid].base < h)
        lo = mid + 1;
      else
        hi = mid;
    }
    if (!lo) { /* below every block */
      *d = h;
      return 1;
    }
    rp_hint = i = lo - 1;
  }
  const rp_block *k = &rp_blocks[i];
  if (h <= k->base + k->n) {
    *b = k;
    return 2;
  }
  *d = h - k->below - k->n;
  return 1;
}

static uint32_t side_get(uint32_t h) {
  for (uint32_t i = side_head[(h * 0x9E3779B1u) >> (32 - SIDE_HEAD_BITS)]; i; i = (*SIDE(i - 1)).next)
    if ((*SIDE(i - 1)).h == h)
      return (*SIDE(i - 1)).m;
  return 0;
}
static void side_put(uint32_t h, uint32_t m) {
  uint32_t *head = &side_head[(h * 0x9E3779B1u) >> (32 - SIDE_HEAD_BITS)];
  for (uint32_t i = *head; i; i = (*SIDE(i - 1)).next)
    if ((*SIDE(i - 1)).h == h) {
      (*SIDE(i - 1)).m = m;
      return;
    }
  uint32_t i = side_n++;
  DIR_GROW(side_dir, i, SIDE_BITS);
  *SIDE(i) = (side_node){h, m, *head};
  *head = i + 1;
}

/* The entry of dense index d, 0 when its leaf is not made. */
static inline uint32_t dense_peek(uint32_t d) {
  uint32_t **dir = map_dir[d >> (MAP_BITS + LEAF_BITS)];
  if (!dir)
    return 0;
  uint32_t *l = dir[(d >> MAP_BITS) & ((1u << LEAF_BITS) - 1)];
  return l ? l[d & ((1u << MAP_BITS) - 1)] : 0;
}
/* The map entry of h, 0 when none is made. */
static inline uint32_t map_peek(uint32_t h) {
  uint32_t d = 0;
  const rp_block *b = NULL;
  return hclass(h, &d, &b) == 1 ? dense_peek(d) : side_get(h);
}
static void map_put(uint32_t h, uint32_t m) {
  uint32_t d = 0;
  const rp_block *b = NULL;
  if (hclass(h, &d, &b) != 1) {
    side_put(h, m);
    return;
  }
  DIR_GROW(map_dir, d, MAP_BITS);
  *MAP(d) = m;
}
static uint32_t rp_materialize(uint32_t h);
static inline uint32_t map_get(uint32_t h) {
  if (rp_watch && h <= rp_wbase)
    rp_outside(h);
  uint32_t d = 0;
  const rp_block *b = NULL;
  int c = hclass(h, &d, &b);
  if (c == 1)
    return dense_peek(d);
  uint32_t m = side_get(h);
  if (!m && c == 2)
    m = rp_materialize(h);
  return m;
}

/* Rail h's record. */
static inline rail_t *rail_rec(uint32_t h) {
  uint32_t m = map_get(h);
  return m & MAP_TOMB ? rail_materialize(h) : m ? &(*SLOT(m - 1)) : rail_blank(h);
}
#define RL(h) (rail_rec((uint32_t)(h)))
/* Rail h's tombstone, NULL when it has a record. */
static inline tomb_t *rail_tomb(uint32_t h) {
  uint32_t m = map_get(h);
  return m & MAP_TOMB ? &(*TOMB(m & ~MAP_TOMB)) : NULL;
}
static inline int rail_live(uint32_t h) { return !rail_tomb(h) && RL(h)->live; }

/* Freed rail h's record to a tombstone when one holds it exactly (above). */
static void rail_bury(uint32_t h) {
  rail_t *r = RL(h);
  if (r->aux) {
    rail_aux *a = r->d.x;
    rail_ext *x = a->ext;
    if (x && !x->r6_ops && !x->r6_old && !x->t_nd && !x->t_meas && !x->ry_t) {
      /* nothing in use: ry_pre, ry_post and ry_ang are read only while ry_t is set, and ry_note rewrites them */
      free(x->ry_pre);
      free(x->ry_post);
      free(x);
      a->ext = NULL;
    }
    if (!a->ext && !a->ndeps) { /* nothing left in it */
      free(a->deps);
      free(a);
      r->aux = 0;
      r->d.in[0] = r->d.in[1] = 0;
    }
  }
  if (r->live || r->aux || r->d.in[0] || rail_nw(r) != 1 || r->val.inl)
    return;
  uint32_t t = tomb_n++;
  if (tomb_n > MAP_TOMB) {
    fprintf(stderr, "cq: chk-core: rail tombstones exhausted\n");
    abort();
  }
  DIR_GROW(tomb_dir, t, TOMB_BITS);
  tomb_t *tb = &(*TOMB(t));
  tb->a = r->t_create | (uint64_t)r->wi << 48;
  tb->b = r->t_write;
  tf_set(tb, tomb_flags(r));
  uint32_t s = map_peek(h) - 1;
  r->val.inl = pool_free;
  pool_free = s + 1;
  map_put(h, t | MAP_TOMB);
}

static inline int32_t *deps_of(rail_t *r) { return r->aux ? r->d.x->deps : r->d.in; }
static inline uint32_t rail_nd(const rail_t *r) { return r->aux ? r->d.x->ndeps : (r->d.in[0] != 0) + (r->d.in[1] != 0); }
static inline rail_ext *rail_x(const rail_t *r) { return r->aux ? r->d.x->ext : NULL; } /* the extension, NULL none */
static uint32_t deps_cap(uint32_t n) {
  uint32_t c = 4;
  while (c < n)
    c <<= 1;
  return c;
}

static rail_aux *aux_of(rail_t *r) {
  if (!r->aux) {
    rail_aux *a = xcalloc(1, sizeof *a);
    uint32_t n = rail_nd(r);
    if (n) {
      a->deps = malloc(deps_cap(n) * sizeof *a->deps);
      if (!a->deps)
        abort();
      memcpy(a->deps, r->d.in, n * sizeof *a->deps);
    }
    a->ndeps = n;
    r->d.x = a;
    r->aux = 1;
  }
  return r->d.x;
}

static rail_ext *ext_of(rail_t *r) {
  rail_aux *a = aux_of(r);
  if (!a->ext)
    a->ext = xcalloc(1, sizeof *a->ext);
  return a->ext;
}

/* src after r's sources (cq-9hzgh: the first two in the record when neither is 0). */
static void deps_append(rail_t *r, int32_t src) {
  if (!r->aux && src) {
    if (!r->d.in[0]) {
      r->d.in[0] = src;
      return;
    }
    if (!r->d.in[1]) {
      r->d.in[1] = src;
      return;
    }
  }
  rail_aux *a = aux_of(r);
  if (!a->deps) {
    a->deps = malloc(deps_cap(1) * sizeof *a->deps);
    if (!a->deps)
      abort();
  } else if (a->ndeps >= 4 && a->ndeps == deps_cap(a->ndeps)) {
    a->deps = realloc(a->deps, 2 * (size_t)a->ndeps * sizeof *a->deps);
    if (!a->deps)
      abort();
  }
  a->deps[a->ndeps++] = src;
}

/* The event clock: a record holds 48 bits of it. */
static void clock_check(void) {
  if (clock_ > TOMB_CLOCK_MAX) {
    fprintf(stderr, "cq: chk-core: the event clock passed 2^48\n");
    abort();
  }
}
uint64_t cqe__tick(void) {
  ++clock_;
  clock_check();
  return clock_;
}
uint32_t cqe__nrails_peek(void) { return nrails; }

/* cq-4593 (BACKEND_ABI 1.13): a gate recorded inside a cq_invert region whose forward form makes a fresh
 * rail got that rail at once (allocations keep their place, at |0>); when the gate is replayed, the next
 * cqe__new is that rail: init is XORed into it (dispatch.c, cqe__prealloc). */
static int32_t prealloc_h;
void cqe__prealloc(int32_t h) { prealloc_h = h; }
/* The replayed compute of a reserved rail: the rail's value is made now (its known-basis reference). */
void cqe__recreated(int32_t h) {
  if (h >= 1 && (uint32_t)h <= nrails)
    (*RL(h)).t_create = (*RL(h)).t_write = cqe__tick();
}

int32_t cqe__new(const char *w, const cqe_val *init, int known, int seed) {
  cqe__init();
  if (prealloc_h > 0) {
    int32_t h = prealloc_h;
    prealloc_h = 0;
    if ((uint32_t)h > nrails || !rail_live((uint32_t)h)) {
      cqe__violation("bad_handle", h, "cq_invert replay: rail %d is not live", (int)h);
    } else {
      if (w && strcmp(wtab[(*RL(h)).wi], w) != 0)
        cqe__violation("width_mismatch", h, "cq_invert replay: rail %d is %s, the gate makes %s", (int)h, wtab[(*RL(h)).wi], w);
      if (init) {
        cqe_val v = rail_v(RL(h));
        cqe__val_xor(&v, init);
      }
      (*RL(h)).known = (*RL(h)).known && known;
      (*RL(h)).t_write = cqe__tick();
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
  if (nrails + 1 >= CQE_RAIL_LIMIT) {
    fprintf(stderr, "cq: chk-core: rail handles exhausted (limit 0x%x, the bus handle)\n",
            (unsigned)CQE_RAIL_LIMIT);
    abort();
  }
  int32_t h = (int32_t)++nrails;
  uint32_t s;
  rail_t *r = pool_take(&s);
  map_put((uint32_t)h, s + 1);
  r->wi = w_intern(w, bits, kind);
  if (rail_nw(r) > 1)
    r->val.wide = xcalloc(rail_nw(r), sizeof *r->val.wide);
  if (init) {
    cqe_val v = rail_v(r);
    cqe__val_xor(&v, init);
  }
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
  if (!rail_live((uint32_t)h)) {
    cqe__violation("use_after_free", h, "%s: rail %d was freed", ctx, (int)h);
    return 1;
  }
  return 0;
}

/* Quiet existence test (no violation). */
int cqe__exists(int32_t h) { return h >= 1 && (uint32_t)h <= nrails; }

/* The getters read a tombstone where it holds the answer; the rest get the record. */
/* A rail's value as a cqe_val: one of the last VAL_RING views (the record holds no cqe_val); its words are the rail's,
 * so a write through it writes the rail. A caller uses it at once (never across VAL_RING more of them). */
#define VAL_RING 256
static cqe_val val_ring[VAL_RING];
static uint32_t val_ring_i;
static cqe_val *val_view(rail_t *r) {
  cqe_val *v = &val_ring[val_ring_i++ % VAL_RING];
  *v = rail_v(r);
  return v;
}
cqe_val *cqe__val(int32_t h) { return val_view(RL(h)); }
const char *cqe__w(int32_t h) {
  tomb_t *t = rail_tomb((uint32_t)h);
  return wtab[t ? (uint16_t)(t->a >> 48) : (*RL(h)).wi];
}
int cqe__known(int32_t h) {
  tomb_t *t = rail_tomb((uint32_t)h);
  return t ? tf_bit(t, TF_KNOWN) : (*RL(h)).known;
}
void cqe__setknown(int32_t h, int k) { (*RL(h)).known = k ? 1 : 0; }
uint64_t cqe__created(int32_t h) {
  tomb_t *t = rail_tomb((uint32_t)h);
  return t ? t->a & TOMB_CLOCK_MAX : (*RL(h)).t_create;
}
uint64_t cqe__last_nd(int32_t h) {
  if (rail_tomb((uint32_t)h))
    return 0;
  rail_t *r = RL(h);
  return rail_x(r) ? rail_x(r)->t_nd : 0;
}
int cqe__measured(int32_t h) {
  tomb_t *t = rail_tomb((uint32_t)h);
  return t ? tf_bit(t, TF_MEASURED) : (*RL(h)).measured;
}
int cqe__frozen(int32_t h) {
  tomb_t *t = rail_tomb((uint32_t)h);
  return t ? tf_bit(t, TF_FROZEN) : (*RL(h)).frozen;
}
int cqe__role(int32_t h) {
  tomb_t *t = rail_tomb((uint32_t)h);
  return t ? (int)(tf_get(t) >> TF_ROLE & 7) : (*RL(h)).role;
}
void cqe__setfenv(int32_t h, int bits) { (*RL(h)).fenv |= (uint8_t)bits; }
void cqe__setrole(int32_t h, int role) { (*RL(h)).role = (uint8_t)role; }
void cqe__set_busz(int32_t h) { (*RL(h)).busz = 1; }
int cqe__busz(int32_t h) {
  tomb_t *t = rail_tomb((uint32_t)h);
  return t ? tf_bit(t, TF_BUSZ) : (*RL(h)).busz;
}
void cqe__set_store_kept(int32_t h) { (*RL(h)).store_kept = 1; }
/* cq-1leyz: rule 14's kept overflow predicate a_K, as run.kept_ak_module identifies it in the lowered program */
void cqe__set_kept_ak(int32_t h) { (*RL(h)).role = 6; }
/* cq-0ldab: rule 20's kept overflow predicate n > K2, as run.kept_k2_module identifies it in the lowered program */
void cqe__set_kept_k2(int32_t h) { (*RL(h)).role = 7; }

void cqe__mark_written(int32_t h) {
  (*RL(h)).written = 1;
  (*RL(h)).busz = 0;
  (*RL(h)).t_write = cqe__tick();
}
/* cq-3o3v: a firing Ry on h that took a C reach changed its value from pre to the reach's value. A
 * later firing Ry on h with the negated angle, with h neither written nor changed since and no C
 * reach of its own, is that Ry's adjoint in this branch (CR rule 10's un-prep): Ry(-θ)·Ry(θ) = I, so
 * h holds pre again (cqe__ry_unprep). */
void cqe__ry_note(int32_t h, uint64_t angle, const cqe_val *pre) {
  rail_t *r = RL(h);
  rail_ext *x = ext_of(r);
  uint32_t nw = rail_nw(r);
  if (!x->ry_pre) {
    x->ry_pre = xcalloc(nw ? nw : 1, sizeof *x->ry_pre);
    x->ry_post = xcalloc(nw ? nw : 1, sizeof *x->ry_post);
  }
  memcpy(x->ry_pre, pre->w, nw * sizeof *x->ry_pre);
  memcpy(x->ry_post, rail_w(r), nw * sizeof *x->ry_post);
  x->ry_ang = angle;
  x->ry_t = cqe__tick();
}
int cqe__ry_unprep(int32_t h, uint64_t angle) {
  if (rail_tomb((uint32_t)h)) /* a tombstone has no Ry in use */
    return 0;
  rail_t *r = RL(h);
  rail_ext *x = rail_x(r);
  if (!x || !x->ry_t || r->t_write > x->ry_t || angle != (x->ry_ang ^ (1ULL << 63)) ||
      memcmp(x->ry_post, rail_w(r), rail_nw(r) * sizeof *x->ry_post) != 0)
    return 0;
  memcpy(rail_w(r), x->ry_pre, rail_nw(r) * sizeof *x->ry_pre);
  x->ry_t = 0;
  return 1;
}
void cqe__ry_forget(int32_t h) {
  if (rail_tomb((uint32_t)h)) /* a tombstone has no Ry in use */
    return;
  if (rail_x(RL(h)))
    rail_x(RL(h))->ry_t = 0;
}
void cqe__mark_nd(int32_t h) {
  (*RL(h)).frozen = 1;
  (*RL(h)).busz = 0;
  ext_of(RL(h))->t_nd = cqe__tick();
}
/* CR rule 2, BACKEND_ABI 1.3 (cq-ihlt): measuring a measured rail again is a classical re-read of
 * its outcome; the rail's measurement (and its time, which kept_entangled reads) stays the first. */
void cqe__mark_measured(int32_t h) {
  if ((*RL(h)).measured)
    return;
  (*RL(h)).measured = 1;
  (*RL(h)).known = 1;
  ext_of(RL(h))->t_meas = cqe__tick();
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
  rail_t *d = RL(into);
  if (d->measured || !(d->frozen || d->image))
    return;
  for (int i = 0; i < n; ++i) {
    if (srcs[i] == into)
      continue;
    tomb_t *t = rail_tomb((uint32_t)srcs[i]);
    if (t) {
      if (!tf_bit(t, TF_MEASURED))
        tf_set(t, tf_get(t) | 1u << TF_IMAGE);
    } else if (!(*RL(srcs[i])).measured) {
      (*RL(srcs[i])).image = 1;
    }
  }
}

/* CR rule 5 sentence 1 ("A consumer that is never uncomputed (a measured, returned, kept or carried rail, a rule-6
 * image) has no `_unc` to wait for") and rule 6; rulings 2 A (cq-o9mx). Rule 6 cleans a dead rail y against its image:
 * t = g(r, ...); y ^= t (copy, leaving y at known |0>); t _unc against r, ...; free(y). The rails t's _unc reads are
 * the clean's images, frozen or not: the rail's content now lives only there, and a live one at exit is a rule-named
 * kept rail (role rule6_image), never a leak. The order of the _unc and free(y) is the lowering's, so whichever comes
 * second marks. t must be made after y's last write: un-copying a copy of t (copy(t, c); copy(t, c)) cleans nothing,
 * and a rail merely derived from a rotated register or a QUANTUM cell is never marked. A load copy never is (rule 5).
 * Nor is an operand its producer's _unc can still clean (r6_cleanable): the inverse reads rule-5 garbage too, a select's
 * condition or a template result ("its inverse reads the garbage", rule 6, 195), and rule 5 still uncomputes that after
 * the inverse; forgetting that _unc is a leak (cq-cuu82). A forgotten _unc of a rail that was only an ordinary template
 * result stays a leak. */
static int r6_cleanable(rail_t *r) {
  const int32_t *deps = deps_of(r);
  uint32_t nd = rail_nd(r);
  for (uint32_t i = 0; i < nd; ++i) {
    if (!rail_live((uint32_t)deps[i]) || RL(deps[i])->t_write > r->t_write)
      return 0;
  }
  return nd > 0;
}

static void r6_mark(const int32_t *ops, uint32_t n) {
  for (uint32_t i = 0; i < n; ++i) {
    tomb_t *t = rail_tomb((uint32_t)ops[i]);
    if (t) { /* no sources: never r6_cleanable */
      if (!tf_bit(t, TF_MEASURED) && !tf_bit(t, TF_LOAD_COPY))
        tf_set(t, tf_get(t) | 1u << TF_R6);
    } else if (!(*RL(ops[i])).measured && !(*RL(ops[i])).load_copy && !r6_cleanable(RL(ops[i]))) {
      (*RL(ops[i])).r6 = 1;
    }
  }
}

void cqe__set_load_copy(int32_t h) { (*RL(h)).load_copy = 1; }

/* Before the XOR of copy(t, y): may this copy be a rule-6 clean of y? */
int cqe__r6_before(int32_t t, int32_t y) { return (*RL(t)).t_create > (*RL(y)).t_write; }

/* After it, and the known-basis rule: y reads known |0>, so t is the inverse of a rule-6 clean. */
void cqe__r6_cleaned(int32_t t, int32_t y) {
  cqe_val yv = rail_v(RL(y));
  if (cqe__val_iszero(&yv) && (*RL(y)).known)
    ext_of(RL(t))->r6_old = y;
}

/* t's _unc, reading the rails ops. */
void cqe__r6_unc(int32_t t, const int32_t *ops, int n) {
  if (rail_tomb((uint32_t)t)) /* a tombstone's r6_old is 0 */
    return;
  rail_ext *tx = rail_x(RL(t));
  int32_t y = tx ? tx->r6_old : 0;
  if (!y)
    return;
  tx->r6_old = 0;
  if (!rail_live((uint32_t)y)) {
    r6_mark(ops, (uint32_t)n);
    return;
  }
  rail_ext *x = ext_of(RL(y));
  int32_t *keep = realloc(x->r6_ops, (size_t)(n ? n : 1) * sizeof *keep);
  if (!keep)
    abort();
  memcpy(keep, ops, (size_t)n * sizeof *keep);
  x->r6_ops = keep;
  x->r6_nops = (uint32_t)n;
}

void cqe__add_dep(int32_t h, int32_t src) {
  rail_t *r = RL(h);
  tomb_t *st = rail_tomb((uint32_t)src);
  /* cq-tt2j: a rail written from the flags is flags (rule 23 lineage) */
  r->fenv |= (st ? tf_get(st) >> TF_FENV : (*RL(src)).fenv) & 1;
  int32_t *deps = deps_of(r);
  uint32_t nd = rail_nd(r);
  for (uint32_t i = 0; i < nd; ++i)
    if (deps[i] == src)
      return;
  deps_append(r, src);
}

void cqe__free(int32_t h) {
  if (rail_tomb((uint32_t)h)) /* freed before: nothing left to drop */
    return;
  rail_t *r = RL(h);
  r->live = 0;
  rail_ext *x = rail_x(r);
  if (x && x->r6_ops) {
    r6_mark(x->r6_ops, x->r6_nops);
    free(x->r6_ops);
    x->r6_ops = NULL;
  }
  /* a freed rail's role is never asked (the exit event lists live rails); its dependency list goes
   * back to the sample arena's free lists for the next rail (cq-8m6v). Its event times stay: a live
   * rail's role reads them. */
  if (r->aux) {
    free(r->d.x->deps);
    r->d.x->deps = NULL;
    r->d.x->ndeps = 0;
  } else {
    r->d.in[0] = r->d.in[1] = 0;
  }
  rail_bury((uint32_t)h);
}

/* ---- cqe.h rail API (families) ------------------------------------------------------------- */

int32_t cqe_new_rail(const char *w, const cqe_val *init, int known) { return cqe__new(w, init, known, 0); }

const cqe_val *cqe_rail(int32_t h) {
  if (cqe__check(h, "cqe_rail") != 0) /* C1: a freed or unknown handle is a violation and NULL */
    return NULL;
  return val_view(RL(h));
}

void cqe_xor_into(int32_t h, const cqe_val *v) {
  if (cqe__check(h, "cqe_xor_into") < 0 || !v)
    return;
  cqe_val rv = rail_v(RL(h));
  cqe__val_xor(&rv, v);
  cqe__mark_written(h);
}

void cqe_set_known(int32_t h, int known) {
  if (cqe__check(h, "cqe_set_known") < 0)
    return;
  (*RL(h)).known = known ? 1 : 0;
}

/* ---- exit -------------------------------------------------------------------------------- */

/* A source of a rail written at t_write received a non-diagonal gate or a measurement after it (the map peeked: a
 * tombstone's and an untouched block rail's t_nd and t_meas are 0, cqe__rp_encode). */
static int deps_entangled(const int32_t *deps, uint32_t nd, uint64_t t_write) {
  for (uint32_t i = 0; i < nd; ++i) {
    uint32_t m = map_peek((uint32_t)deps[i]);
    if (!m || (m & MAP_TOMB))
      continue;
    const rail_ext *s = rail_x(&(*SLOT(m - 1)));
    if (s && ((s->t_nd && s->t_nd > t_write) || (s->t_meas && s->t_meas > t_write)))
      return 1;
  }
  return 0;
}

static const char *exit_role_r(const rail_t *r, const int32_t *deps, uint32_t nd) {
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
  if (r->role == 6)
    return "a_K";
  if (r->role == 7)
    return "n>K2";
  if (r->frozen || r->image)
    return "frozen";
  if (r->store_kept)
    return "store_kept";
  if (deps_entangled(deps, nd, r->t_write))
    return "kept_entangled";
  if (r->fenv & 2)
    return "fenv_mode";
  if ((r->fenv & 1) && !strcmp(wtab[r->wi], "i32")) /* rule 23's flags are i32 bits; an i1 written from a flags-looking rail is not */
    return "fenv_flags";
  if (r->seed && !r->written)
    return "seed";
  if (r->r6)
    return "rule6_image";
  return "garbage";
}

static const char *exit_role(int32_t h) {
  rail_t *r = RL(h);
  return exit_role_r(r, deps_of(r), rail_nd(r));
}

/* ---- the exit event's live list (cq-9hzgh, cq-pckdl) ----------------------------------------------------------
 *
 * Every live rail at exit is in the list exactly once. Without a compact trace each rail is its own entry
 * {"h","w","v","role","known"}, in handle order. In a compact trace the list is cut into chunks and each chunk is
 * written once in full and then by reference (cq-pckdl: a replayed snprintf left 145M live rails at exit, in a stream
 * that repeats every ~950 handles with a few counters in it; no row of evenly spaced rails of one key covers more
 * than a handful of them):
 *   - a chunk is a run of consecutive live rails, cut where a rolling hash of the last rails' keys and handle gaps
 *     (gear hash, about 64 rails) hits a mark, between EXIT_CHUNK_MIN and EXIT_CHUNK_MAX rails: the cuts follow the
 *     content, so a stretch that repeats is cut the same way each time, wherever it starts;
 *   - its content is its rails' handles relative to its first and their keys (width, value, role, known flag);
 *   - the first chunk of a content is written as rows {"h","w","v","role","known"} or, for n rails at h, h + step,
 *     ... of one key, {"h","n","step","w","v","role","known"} (one open row per key within the chunk);
 *   - a later chunk of the same content writes, at its first, the content's rows once as {"def":id,"rows":[...]}
 *     with "h" relative to the chunk's first rail, and every chunk of that content after it as a use
 *     {"use":id,"h":first} or, for chunks at first, first + step, ..., {"use":id,"h":first,"n":n,"step":step}
 *     (one open use run per content; written when the next chunk does not continue it, or at the end).
 * A use stands for the def's rows moved to its first handle: the rails it covers are exactly the def's, shifted.
 * run.py reads the list row by row (cqcheck.kept). The output depends only on the sequence of live rails (handles,
 * widths, values, roles, known flags), never on how a rail was made: a replayed call's rails give the bytes the real
 * calls give (tests/replay compares the traces), and nothing in it depends on an address. The contents kept for
 * matching are bounded (EXIT_ARENA_MAX rails, EXIT_KEYS_MAX keys): past the bound a chunk is only written in full. */
#define EXIT_CHUNK_MIN 32u
#define EXIT_CHUNK_MAX 1024u
#define EXIT_ARENA_MAX (1u << 23)
#define EXIT_KEYS_MAX (1u << 22)
#define EXIT_PATS_MAX (1u << 20)

/* One row: n rails at handles h, h + step, ... of one width, value, role and known flag. */
typedef struct {
  uint32_t h, n, step;
  const char *w, *role;
  int known;
  const char *v;
} live_row;

typedef struct {
  const char *w, *role; /* static strings (wtab, exit_role) */
  int known;
  char *v;
  uint64_t hash; /* of the content: width, value, role, known */
} xkey;
typedef struct {
  uint32_t h, key; /* a handle (relative to its chunk's first in the arena) and a key */
} xtok;
typedef struct {
  uint64_t hash;
  uint32_t off, len; /* its content in the arena */
  int64_t id;        /* its def's id once written, else -1 */
  uint32_t u_h, u_n, u_step; /* the open use run (u_n 0: none) */
} xpat;
static struct {
  int first; /* no entry written yet */
  xkey *keys;
  uint32_t nkeys, capkeys, *kslot, nkslot;
  xtok *chunk;
  uint32_t nchunk;
  xpat *pats;
  uint32_t npats, cappats, *pslot, npslot;
  xtok *arena;
  uint32_t narena, caparena;
  uint32_t *open, *stamp, epoch; /* per key: its open row in the chunk being written (stamp == epoch) */
  live_row *rows;
  uint32_t caprows;
  uint64_t gear;
  uint32_t last_h;
  int64_t next_id;
} XM;

static uint64_t str_hash(const char *s) {
  uint64_t x = 1469598103934665603ull;
  for (; *s; ++s)
    x = (x ^ (uint8_t)*s) * 1099511628211ull;
  return x;
}

static uint64_t mix64(uint64_t x) {
  x ^= x >> 31;
  x *= 0x7FB5D329728EA185ull;
  x ^= x >> 27;
  x *= 0x81DADEF4BC2DD44Dull;
  return x ^ (x >> 33);
}

/* A copy of s (never the C library's strdup: the program under test may define it, rt_replay.h). */
static char *exit_strdup(const char *s) {
  size_t n = 0;
  while (s[n])
    ++n;
  char *d = xcalloc(n + 1, 1);
  cqe__rp_cpy(d, s, n);
  return d;
}

static void *exit_grow(void *p, uint32_t *cap, uint32_t need, size_t sz) {
  if (need <= *cap)
    return p;
  uint32_t c = *cap ? *cap : 256;
  while (c < need)
    c *= 2;
  p = realloc(p, (size_t)c * sz);
  if (!p)
    abort();
  *cap = c;
  return p;
}

static void live_put(const live_row *r, int64_t rel_of) {
  const char *sep = XM.first ? "" : ",";
  XM.first = 0;
  long long h = rel_of >= 0 ? (long long)r->h - rel_of : (long long)r->h;
  if (r->n > 1)
    fprintf(trace_f, "%s{\"h\":%lld,\"n\":%u,\"step\":%u,\"w\":\"%s\",\"v\":\"%s\",\"role\":\"%s\",\"known\":%s}", sep, h,
            r->n, r->step, r->w, r->v, r->role, r->known ? "true" : "false");
  else
    fprintf(trace_f, "%s{\"h\":%lld,\"w\":\"%s\",\"v\":\"%s\",\"role\":\"%s\",\"known\":%s}", sep, h, r->w, r->v,
            r->role, r->known ? "true" : "false");
}

/* The rows of n rails (handles h + base, keys), one open row per key, written in the order they open; with rel, their
 * handles relative to base (a def's rows: the entries carry no separator of their own, the def's list does). */
static void exit_rows(const xtok *t, uint32_t n, uint32_t base, int rel) {
  if (++XM.epoch == 0) { /* the stamps wrapped: forget them all */
    cqe__rp_zero(XM.stamp, (size_t)XM.capkeys * sizeof *XM.stamp);
    XM.epoch = 1;
  }
  XM.rows = exit_grow(XM.rows, &XM.caprows, n, sizeof *XM.rows);
  uint32_t nr = 0;
  for (uint32_t i = 0; i < n; ++i) {
    uint32_t h = t[i].h + base, k = t[i].key;
    if (XM.stamp[k] == XM.epoch) {
      live_row *o = &XM.rows[XM.open[k]];
      if (o->n == 1 || h == o->h + o->n * o->step) {
        if (o->n == 1)
          o->step = h - o->h;
        o->n++;
        continue;
      }
    }
    const xkey *K = &XM.keys[k];
    XM.rows[nr] = (live_row){h, 1, 0, K->w, K->role, K->known, K->v};
    XM.stamp[k] = XM.epoch;
    XM.open[k] = nr++;
  }
  int was = XM.first;
  for (uint32_t i = 0; i < nr; ++i) {
    if (rel && i == 0)
      XM.first = 1; /* the first row of a def's list */
    live_put(&XM.rows[i], rel ? (int64_t)base : -1);
  }
  if (rel)
    XM.first = was;
}

static void exit_use_put(const xpat *p) {
  fprintf(trace_f, "%s{\"use\":%lld,\"h\":%u", XM.first ? "" : ",", (long long)p->id, p->u_h);
  if (p->u_n > 1)
    fprintf(trace_f, ",\"n\":%u,\"step\":%u", p->u_n, p->u_step);
  fputc('}', trace_f);
  XM.first = 0;
}

/* Write every open use run and forget every content and key; clear: for more chunks to come (a table at its bound). */
static void exit_reset(int clear) {
  for (uint32_t i = 0; i < XM.npats; ++i)
    if (XM.pats[i].u_n)
      exit_use_put(&XM.pats[i]);
  for (uint32_t i = 0; i < XM.nkeys; ++i)
    free(XM.keys[i].v);
  XM.nkeys = XM.npats = XM.narena = 0;
  if (clear && XM.kslot)
    cqe__rp_zero(XM.kslot, (size_t)XM.nkslot * sizeof *XM.kslot);
  if (clear && XM.pslot)
    cqe__rp_zero(XM.pslot, (size_t)XM.npslot * sizeof *XM.pslot);
}

/* Open addressing: the slot of hash x in a table of n (a power of 2) slots, by eq. */
#define XM_FIND(slots, nslots, x, eq)                                                                                  \
  ({                                                                                                                   \
    uint32_t i_ = (uint32_t)(x) & ((nslots)-1);                                                                        \
    while ((slots)[i_] && !(eq((slots)[i_] - 1)))                                                                      \
      i_ = (i_ + 1) & ((nslots)-1);                                                                                    \
    i_;                                                                                                                \
  })

/* The chunk being cut ends: written in full, as a def and a use, or as a use. */
static void exit_chunk_end(void) {
  uint32_t n = XM.nchunk;
  if (!n)
    return;
  XM.nchunk = 0;
  uint32_t base = XM.chunk[0].h;
  uint64_t x = mix64(n);
  for (uint32_t i = 0; i < n; ++i) {
    XM.chunk[i].h -= base;
    x = mix64(x ^ ((uint64_t)XM.chunk[i].h << 32 | XM.chunk[i].key));
  }
  if (!XM.pslot) {
    XM.npslot = 2 * EXIT_PATS_MAX;
    XM.pslot = xcalloc(XM.npslot, sizeof *XM.pslot);
  }
#define PAT_EQ(j)                                                                                                      \
  (XM.pats[j].hash == x && XM.pats[j].len == n && cqe__rp_eq(XM.arena + XM.pats[j].off, XM.chunk, n * sizeof(xtok)))
  uint32_t sl = XM_FIND(XM.pslot, XM.npslot, x, PAT_EQ);
#undef PAT_EQ
  if (XM.pslot[sl]) {
    xpat *p = &XM.pats[XM.pslot[sl] - 1];
    if (p->id < 0) { /* its second chunk: the def first */
      p->id = XM.next_id++;
      fprintf(trace_f, "%s{\"def\":%lld,\"rows\":[", XM.first ? "" : ",", (long long)p->id);
      XM.first = 0;
      exit_rows(XM.arena + p->off, n, 0, 1);
      fputs("]}", trace_f);
    }
    if (p->u_n && (p->u_n == 1 ? base > p->u_h : base == p->u_h + p->u_n * p->u_step)) {
      if (p->u_n == 1)
        p->u_step = base - p->u_h;
      p->u_n++;
      return;
    }
    if (p->u_n)
      exit_use_put(p);
    p->u_h = base;
    p->u_n = 1;
    return;
  }
  exit_rows(XM.chunk, n, base, 0); /* a content's first chunk */
  if (XM.npats == EXIT_PATS_MAX || XM.narena + n > EXIT_ARENA_MAX)
    return; /* kept for matching no more */
  XM.pats = exit_grow(XM.pats, &XM.cappats, XM.npats + 1, sizeof *XM.pats);
  XM.arena = exit_grow(XM.arena, &XM.caparena, XM.narena + n, sizeof *XM.arena);
  cqe__rp_cpy(XM.arena + XM.narena, XM.chunk, n * sizeof(xtok));
  XM.pats[XM.npats] = (xpat){x, XM.narena, n, -1, 0, 0, 0};
  XM.narena += n;
  XM.pslot[sl] = ++XM.npats;
}

/* One live rail into the exit event's list (hx is the caller's: copied when kept). */
static void exit_feed(uint32_t h, const char *w, const char *hx, const char *role, int known) {
  if (!compact) { /* every rail its own entry, in handle order */
    live_row one = {h, 1, 0, w, role, known, hx};
    live_put(&one, -1);
    return;
  }
  if (!XM.kslot) {
    XM.nkslot = 2 * EXIT_KEYS_MAX;
    XM.kslot = xcalloc(XM.nkslot, sizeof *XM.kslot);
  }
  uint64_t kh = mix64(str_hash(w) ^ mix64(str_hash(hx)) ^ mix64(str_hash(role) + (uint64_t)known));
#define KEY_EQ(j)                                                                                                      \
  (XM.keys[j].hash == kh && XM.keys[j].known == known && !strcmp(XM.keys[j].w, w) && !strcmp(XM.keys[j].role, role) && \
   !strcmp(XM.keys[j].v, hx))
  uint32_t sl = XM_FIND(XM.kslot, XM.nkslot, kh, KEY_EQ);
  if (!XM.kslot[sl]) {
    if (XM.nkeys == EXIT_KEYS_MAX) { /* every key in use: the chunk so far, then afresh */
      exit_chunk_end();
      exit_reset(1);
      sl = XM_FIND(XM.kslot, XM.nkslot, kh, KEY_EQ);
    }
    uint32_t oldcap = XM.capkeys;
    XM.keys = exit_grow(XM.keys, &XM.capkeys, XM.nkeys + 1, sizeof *XM.keys);
    if (XM.capkeys != oldcap) { /* the per-key row slots grow with the keys */
      XM.open = realloc(XM.open, (size_t)XM.capkeys * sizeof *XM.open);
      XM.stamp = realloc(XM.stamp, (size_t)XM.capkeys * sizeof *XM.stamp);
      if (!XM.open || !XM.stamp)
        abort();
      cqe__rp_zero(XM.stamp + oldcap, (size_t)(XM.capkeys - oldcap) * sizeof *XM.stamp);
    }
    XM.keys[XM.nkeys] = (xkey){w, role, known, exit_strdup(hx), kh};
    XM.stamp[XM.nkeys] = 0;
    XM.kslot[sl] = ++XM.nkeys;
  }
#undef KEY_EQ
  uint32_t k = XM.kslot[sl] - 1;
  XM.gear = (XM.gear << 1) + mix64(kh ^ (uint64_t)(h - XM.last_h) * 0x9E3779B97F4A7C15ull);
  XM.last_h = h;
  if (!XM.chunk)
    XM.chunk = xcalloc(EXIT_CHUNK_MAX, sizeof *XM.chunk);
  XM.chunk[XM.nchunk++] = (xtok){h, k};
  if (XM.nchunk == EXIT_CHUNK_MAX || (XM.nchunk >= EXIT_CHUNK_MIN && XM.gear >> 57 == 0))
    exit_chunk_end();
}

/* The end of the list: the last chunk and every open use run; everything freed. */
static void exit_finish(void) {
  exit_chunk_end();
  exit_reset(0);
  free(XM.keys);
  free(XM.kslot);
  free(XM.chunk);
  free(XM.pats);
  free(XM.pslot);
  free(XM.arena);
  free(XM.open);
  free(XM.stamp);
  free(XM.rows);
  cqe__rp_zero(&XM, sizeof XM);
}

static int rp_exit_rail(const rp_block *b, uint32_t h);

/* ---- the exit event's replayed blocks (cq-kcn5i; Fable ruling 2026-11-09, DECISIONS) -----------------------------
 *
 * In a compact trace an untouched replayed call is never fed rail by rail: its rails are its record's, so the record
 * is the pattern. Per record (once per sample, at the first block of it that writes a use) {"def":id,"rows":[...]}
 * holds the record's rails live at its end, handles relative to the block base, roles as exit_role_r gives them when
 * no source of the rail received a gate or measurement after its write; each block then writes
 * {"use":id,"h":base[,"n","step"][,"skip":[rel,...]]}: skip names the def's rails the caller made (map_peek), which
 * are written as rows of their own from the rail table (or not at all once freed). Blocks of one record at one stride
 * with one skip set fold into one use run. A block where a source of a live record rail (an argument or a made block
 * rail) received a non-diagonal gate or a measurement takes the per-rail path instead (rp_exit_rail): its roles may
 * differ from the def's. The handle set is every live rail exactly once, as before. No chunk spans a block (the
 * chunker is cut at each), so no two uses overlap except a use run's hull (cqcheck.kept.KeptIndex). */
typedef struct {
  const cqe_rp_rails *rr;
  int64_t id;               /* its def's id once written, else -1 */
  uint32_t nlive, *live;    /* indices of the record's rails live at its end */
  uint32_t nrefs;
  int32_t *refs;            /* the distinct nonzero source refs of those rails, as the record holds them */
  uint32_t u_h, u_n, u_step; /* the open use run (u_n 0: none) and its skip set */
  uint32_t u_nskip, *u_skip, u_capskip;
} xrec;
static struct {
  xrec *recs;
  uint32_t nrecs, caprecs, *slot, nslot;
  uint32_t *skip, capskip;
} XR;

static int rp_exit_key(const cqe_rp_rails *rr, uint32_t i, live_row *row, const int32_t **refs, uint32_t *nrefs);

static uint32_t xr_ptr_hash(const void *p) { return (uint32_t)mix64((uint64_t)(uintptr_t)p); }

/* The block table entry of record rr, made (and its live rails and refs read) at its first block. */
static xrec *exit_rec(const cqe_rp_rails *rr) {
  if (2 * (XR.nrecs + 1) > XR.nslot) { /* grow and rehash */
    uint32_t n = XR.nslot ? 2 * XR.nslot : 1024;
    uint32_t *s = xcalloc(n, sizeof *s);
    for (uint32_t j = 0; j < XR.nrecs; ++j) {
      uint32_t i = xr_ptr_hash(XR.recs[j].rr) & (n - 1);
      while (s[i])
        i = (i + 1) & (n - 1);
      s[i] = j + 1;
    }
    free(XR.slot);
    XR.slot = s;
    XR.nslot = n;
  }
  uint32_t i = xr_ptr_hash(rr) & (XR.nslot - 1);
  while (XR.slot[i] && XR.recs[XR.slot[i] - 1].rr != rr)
    i = (i + 1) & (XR.nslot - 1);
  if (XR.slot[i])
    return &XR.recs[XR.slot[i] - 1];
  XR.recs = exit_grow(XR.recs, &XR.caprecs, XR.nrecs + 1, sizeof *XR.recs);
  xrec *x = &XR.recs[XR.nrecs];
  XR.slot[i] = ++XR.nrecs;
  cqe__rp_zero(x, sizeof *x);
  x->rr = rr;
  x->id = -1;
  x->live = xcalloc(rr->n ? rr->n : 1, sizeof *x->live);
  uint32_t capr = 0, nset = 0, *set = NULL; /* the refs seen, open addressing on ref + 1 */
  for (uint32_t k = 0; k < rr->n; ++k) {
    live_row row;
    const int32_t *refs;
    uint32_t nr;
    if (!rp_exit_key(rr, k, &row, &refs, &nr))
      continue;
    x->live[x->nlive++] = k;
    for (uint32_t j = 0; j < nr; ++j) {
      if (!refs[j])
        continue;
      if (2 * (x->nrefs + 1) > nset) {
        uint32_t n = nset ? 2 * nset : 64;
        free(set);
        set = xcalloc(n, sizeof *set);
        nset = n;
        for (uint32_t q = 0; q < x->nrefs; ++q) {
          uint32_t s = (uint32_t)mix64((uint32_t)x->refs[q]) & (n - 1);
          while (set[s])
            s = (s + 1) & (n - 1);
          set[s] = q + 1;
        }
      }
      uint32_t s = (uint32_t)mix64((uint32_t)refs[j]) & (nset - 1);
      while (set[s] && x->refs[set[s] - 1] != refs[j])
        s = (s + 1) & (nset - 1);
      if (set[s])
        continue;
      x->refs = exit_grow(x->refs, &capr, x->nrefs + 1, sizeof *x->refs);
      x->refs[x->nrefs] = refs[j];
      set[s] = ++x->nrefs;
    }
  }
  free(set);
  return x;
}

/* A source rail d received a non-diagonal gate or a measurement at any time (deps_entangled's test, without its
 * after-the-write part: when this is 0 for every source, deps_entangled is 0 for every rail of the block). */
static int exit_dep_touched(int32_t d) {
  uint32_t m = map_peek((uint32_t)d);
  if (!m || (m & MAP_TOMB))
    return 0;
  const rail_ext *s = rail_x(&(*SLOT(m - 1)));
  return s && (s->t_nd || s->t_meas);
}

/* A live rail of the rail table at the exit event: fed to the chunker, or with plain its own row. */
static void exit_table_rail(uint32_t h, int plain) {
  if (rail_tomb(h))
    return;
  rail_t *r = RL(h);
  if (!r->live)
    return;
  char vb[3 + 16 * 2 + 1];
  cqe_val v = rail_v(r);
  char *hx = v.nw <= 2 ? cqe__hex(&v, vb) : cqe__hexa(&v);
  if (plain) {
    live_row one = {h, 1, 0, wtab[r->wi], exit_role((int32_t)h), r->known, hx};
    live_put(&one, -1);
  } else {
    exit_feed(h, wtab[r->wi], hx, exit_role((int32_t)h), r->known);
  }
  if (hx != vb)
    free(hx);
}

/* The def of record x: its live rails' rows, n rails of one key at one stride folded into one row, in the order they
 * open (the keys' table is the def's own: width and role are static strings, compared by address). */
static void exit_def_put(xrec *x) {
  x->id = XM.next_id++;
  fprintf(trace_f, "%s{\"def\":%lld,\"rows\":[", XM.first ? "" : ",", (long long)x->id);
  XM.first = 0;
  uint32_t n = x->nlive, ns = 16;
  while (ns < 2 * n)
    ns *= 2;
  uint32_t *open = xcalloc(ns, sizeof *open); /* key slot -> its open row + 1 */
  live_row *rows = xcalloc(n ? n : 1, sizeof *rows);
  uint32_t nr = 0;
  for (uint32_t k = 0; k < n; ++k) {
    live_row r;
    const int32_t *refs;
    uint32_t nrf;
    rp_exit_key(x->rr, x->live[k], &r, &refs, &nrf);
    r.h = x->live[k] + 1;
    r.n = 1;
    r.step = 0;
    uint32_t s = (uint32_t)mix64(str_hash(r.v) ^ (uint64_t)(uintptr_t)r.w * 31 ^ (uint64_t)(uintptr_t)r.role * 7 ^
                                 (uint64_t)r.known) & (ns - 1);
    for (; open[s]; s = (s + 1) & (ns - 1)) {
      const live_row *o = &rows[open[s] - 1];
      if (o->w == r.w && o->role == r.role && o->known == r.known && !strcmp(o->v, r.v))
        break;
    }
    if (open[s]) {
      live_row *o = &rows[open[s] - 1];
      if (o->n == 1 || r.h == o->h + o->n * o->step) {
        if (o->n == 1)
          o->step = r.h - o->h;
        o->n++;
        continue;
      }
    }
    rows[nr] = r;
    open[s] = ++nr;
  }
  XM.first = 1;
  for (uint32_t i = 0; i < nr; ++i)
    live_put(&rows[i], -1);
  XM.first = 0;
  fputs("]}", trace_f);
  free(rows);
  free(open);
}

static void exit_use_run_put(xrec *x) {
  fprintf(trace_f, "%s{\"use\":%lld,\"h\":%u", XM.first ? "" : ",", (long long)x->id, x->u_h);
  if (x->u_n > 1)
    fprintf(trace_f, ",\"n\":%u,\"step\":%u", x->u_n, x->u_step);
  if (x->u_nskip) {
    fputs(",\"skip\":[", trace_f);
    for (uint32_t i = 0; i < x->u_nskip; ++i)
      fprintf(trace_f, "%s%u", i ? "," : "", x->u_skip[i]);
    fputc(']', trace_f);
  }
  fputc('}', trace_f);
  XM.first = 0;
  x->u_n = 0;
}

/* Replayed block b at the exit event. */
static void exit_block(const rp_block *b) {
  exit_chunk_end(); /* no chunk spans a block */
  xrec *x = exit_rec(b->rr);
  int touched = 0;
  for (uint32_t j = 0; j < x->nrefs && !touched; ++j)
    touched = exit_dep_touched(cqe__rp_dec_handle(x->refs[j], b->base, RP_ARGS(b)));
  if (touched) { /* a role may depend on the caller: rail by rail, as without a def */
    for (uint32_t h = b->base + 1; h <= b->base + b->n; ++h) {
      if (!map_peek(h))
        rp_exit_rail(b, h);
      else
        exit_table_rail(h, 0);
    }
    exit_chunk_end();
    return;
  }
  uint32_t nskip = 0;
  if (rp_nmat) /* some block rail was made this sample */
    for (uint32_t k = 0; k < x->nlive; ++k) {
      uint32_t h = b->base + 1 + x->live[k];
      if (!map_peek(h))
        continue;
      XR.skip = exit_grow(XR.skip, &XR.capskip, nskip + 1, sizeof *XR.skip);
      XR.skip[nskip++] = x->live[k] + 1;
      exit_table_rail(h, 1);
    }
  if (nskip == x->nlive)
    return; /* every live rail of it made: rows of their own */
  if (x->id < 0)
    exit_def_put(x);
  if (x->u_n && nskip == x->u_nskip && cqe__rp_eq(XR.skip, x->u_skip, nskip * sizeof *XR.skip) &&
      (x->u_n == 1 ? b->base > x->u_h : b->base == x->u_h + x->u_n * x->u_step)) {
    if (x->u_n == 1)
      x->u_step = b->base - x->u_h;
    x->u_n++;
    return;
  }
  if (x->u_n)
    exit_use_run_put(x);
  x->u_h = b->base;
  x->u_n = 1;
  x->u_skip = exit_grow(x->u_skip, &x->u_capskip, nskip ? nskip : 1, sizeof *x->u_skip);
  cqe__rp_cpy(x->u_skip, XR.skip, nskip * sizeof *XR.skip);
  x->u_nskip = nskip;
}

/* Every open use run written; the table freed. */
static void exit_blocks_finish(void) {
  for (uint32_t i = 0; i < XR.nrecs; ++i) {
    xrec *x = &XR.recs[i];
    if (x->u_n)
      exit_use_run_put(x);
    free(x->live);
    free(x->refs);
    free(x->u_skip);
  }
  free(XR.recs);
  free(XR.slot);
  free(XR.skip);
  cqe__rp_zero(&XR, sizeof XR);
}


/* The exit event, written straight to the trace (cq-9hzgh: never built in memory; a looping sample's list
 * once reached 6 GB). Its live list holds every live rail exactly once, as rows, defs and uses (the live list
 * section above, cq-pckdl). Not counted against the running sample's trace cap (cq-pckdl): that cap stops a sample that logs without end
 * (cq-3fjt), and the exit event comes once, after the sample's code ended; counted, it could only turn a finished
 * sample into a trace_cap failure after the event is already written. The file cap ($CQE_FILE_MAX) still bounds the
 * trace; the chunks keep the event to about one entry per repeated stretch (snprintf@0: 145M rails, 18 MB). */
static void at_exit_handler(void) {
  if (shot_muted)
    return;
  /* the host part of rule 23's flags, compare._final_flags (read first: nothing below touches them) */
  int host_flags = fetestexcept(FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW | FE_UNDERFLOW | FE_INEXACT);
  static const char head[] = "{\"ev\":\"exit\",\"live\":[";
  fputs(head, trace_f);
  XM.first = 1;
  size_t bi = 0; /* cq-kcn5i: the next replay block */
  for (uint32_t h = 1; h <= nrails; ++h) {
    while (bi < rp_nblocks && rp_blocks[bi].base + rp_blocks[bi].n < h)
      ++bi;
    if (bi < rp_nblocks && h > rp_blocks[bi].base) {
      if (compact) { /* a replayed call: a use of its record's def (exit_block) */
        exit_block(&rp_blocks[bi]);
        h = rp_blocks[bi].base + rp_blocks[bi].n;
        continue;
      }
      if (!map_peek(h)) { /* an untouched rail of a replayed call */
        rp_exit_rail(&rp_blocks[bi], h);
        continue;
      }
    }
    exit_table_rail(h, 0);
  }
  exit_blocks_finish();
  exit_finish();
  fprintf(trace_f, "],\"violations\":%lu,\"host_flags\":%d}\n", nviolations, host_flags);
  if (!shot_buffered)
    fflush(trace_f);
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
static void pid_atfork_child(void);
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
      *mark = ARENA_FREED;   /* a large block is marked too */
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
void cqe__sites_resolve(void) __attribute__((weak)); /* dispatch.c (cq-9hzgh) */
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
  pthread_atfork(NULL, NULL, pid_atfork_child);
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

/* A cqrt_free of rail h with its known flag: counted into the running sample's summary; whether its
 * free event is written (always outside a sample and without the compact trace; in a sample of a
 * compact trace only a dirty one, which compare reports). */
static void rp_free_log(int32_t h); /* cq-kcn5i, the end of this file */
int cqe__free_note(int32_t h, int known) {
  if (cqe__rp_window)
    rp_free_log(h);
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

/* This process's pid, cached (cq-9hzgh: malloc and free ask sample_running at every block, and getpid is a
 * system call); a forked child forgets it (pid_atfork_child, registered by shot_ctor). */
static pid_t self_pid;
static void pid_atfork_child(void) { self_pid = 0; }
static pid_t my_pid(void) {
  if (!self_pid)
    self_pid = getpid();
  return self_pid;
}

static int sample_running(void) { return R && R->in_sample && my_pid() == R->worker; }
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
    if (cqe__sites_resolve)
      cqe__sites_resolve(); /* cq-9hzgh: every call site parsed once, before the setup's snapshot */
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
    cqe__logf("{\"ev\":\"host_end\",\"code\":%d}", R->code); /* rule 16: the program itself made the host exit */
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

/* ---- clone replay (cq-kcn5i): the rail store's side (rt_replay.c has the design) ------------------------------ */

/* One rail of a window's record (cqe_rp_rails.blob), 8-byte aligned: this header, its nw value words, its ndeps
 * sources and nr6 rule-6 operands (each an encoded handle, rp_enc), padding to 8 bytes, and with RF_LOAD the address
 * of the bus load that made it. Clocks are relative to the window's start (0: never). */
typedef struct {
  uint32_t flags; /* tomb_flags | RF_* */
  uint16_t wi, pad_;
  uint32_t nw, ndeps, nr6;
  int32_t r6_old;
  uint32_t tc, tw;
} rp_rail;
_Static_assert(sizeof(rp_rail) == 32, "rp_rail: 32 bytes");
#define RF_LIVE (1u << 16)
#define RF_TOMB (1u << 17)
#define RF_EXT (1u << 18)
#define RF_R6OPS (1u << 19)
#define RF_LOAD (1u << 20)
#define RF_FIRE (1u << 21)

/* A handle as a record holds it: 0 none; > 0 the window's rail base + e; < 0 the call's handle argument -e - 1. *ok
 * drops to 0 for any other rail (outside the clone's reach: the window is not recordable). */
static int32_t rp_enc(int32_t h, uint32_t base, const int32_t *args, int nargs, int *ok) {
  if (h == 0)
    return 0;
  if ((uint32_t)h > base && (uint32_t)h <= nrails && h > 0)
    return (int32_t)((uint32_t)h - base);
  for (int i = 0; i < nargs; ++i)
    if (args[i] == h)
      return -i - 1;
  *ok = 0;
  return 0;
}
int32_t cqe__rp_enc_handle(int32_t h, uint32_t base, const int32_t *args, int nargs, int *ok) {
  return rp_enc(h, base, args, nargs, ok);
}
int32_t cqe__rp_dec_handle(int32_t e, uint32_t base, const int32_t *args) {
  return e > 0 ? (int32_t)(base + (uint32_t)e) : e < 0 ? args[-e - 1] : 0;
}

static uint32_t rp_rel(uint64_t t, uint64_t c0, int *ok) {
  if (!t)
    return 0;
  if (t <= c0 || t - c0 > UINT32_MAX) {
    *ok = 0;
    return 0;
  }
  return (uint32_t)(t - c0);
}
static inline uint64_t rp_abs(uint32_t rel, uint64_t c0) { return rel ? c0 + rel : 0; }

static inline const rp_rail *rp_hdr(const cqe_rp_rails *rr, uint32_t i) {
  return (const rp_rail *)(const void *)(rr->blob.p + rr->off[i]);
}
static inline const uint64_t *rp_words(const rp_rail *e) { return (const uint64_t *)(const void *)(e + 1); }
static inline const int32_t *rp_refs(const rp_rail *e) { return (const int32_t *)(const void *)(rp_words(e) + e->nw); }
static inline const uint64_t *rp_loadaddr(const rp_rail *e) {
  size_t refs = 4 * ((size_t)e->ndeps + e->nr6);
  return (const uint64_t *)(const void *)((const uint8_t *)rp_refs(e) + ((refs + 7) & ~(size_t)7));
}

/* The window's frees, base-relative, in order (cqe__free_note). */
static uint32_t *rp_fl;
static size_t rp_fln, rp_flcap;
static void rp_free_log(int32_t h) {
  if (h <= 0 || (uint32_t)h <= rp_wbase || (uint32_t)h > nrails) {
    cqe__rp_dirty = 1;
    return;
  }
  if (rp_fln == rp_flcap) {
    rp_flcap = rp_flcap ? 2 * rp_flcap : 256;
    rp_fl = realloc(rp_fl, rp_flcap * sizeof *rp_fl);
    if (!rp_fl)
      abort();
  }
  rp_fl[rp_fln++] = (uint32_t)h - rp_wbase;
}
const uint32_t *cqe__rp_frees(size_t *n) {
  *n = rp_fln;
  return rp_fl;
}
void cqe__rp_frees_apply(const uint32_t *rel, size_t n, uint32_t base) {
  if (!sample_running())
    return;
  R->freed_n += (long)n;
  for (size_t i = 0; i < n; ++i)
    R->freed_dig = (R->freed_dig ^ (base + rel[i])) * 0x100000001b3ULL;
}

void cqe__rp_watch(uint32_t base, const int32_t *args, int nargs, int on) {
  rp_watch = cqe__rp_window = on;
  if (on) {
    rp_wbase = base;
    rp_wargs = args;
    rp_wnargs = nargs;
    rp_fln = 0;
  }
}

uint32_t cqe__rp_nrails(void) { return nrails; }
uint64_t cqe__rp_clock(void) { return clock_; }
unsigned long long cqe__rp_steps(void) { return shot_steps; }
int32_t cqe__rp_prealloc(void) { return prealloc_h; }
long cqe__rp_shot_k(void) { return R ? R->base + R->cur : 0; }
uint64_t cqe__rp_materialized(void) { return rp_nmat; }

/* d more basic blocks, as the real run's __sanitizer_cov_trace_pc calls would have counted them. */
void cqe__rp_steps_add(unsigned long long d) {
  unsigned long long before = shot_steps;
  if (shot_step_cap != ~0ULL && before + d > shot_step_cap) {
    if (sample_running()) {
      shot_steps = shot_step_cap;
      shot_over_budget();
    }
    shot_steps = (before + d) % (shot_step_cap + 1); /* the setup: every crossing restarts the count */
  } else {
    shot_steps = before + d;
  }
  if ((before >> 16) != (shot_steps >> 16))
    shot_output_check();
}

/* The key part of the call's handle arguments: per argument the index of an earlier equal one, or its rail as the
 * clone can read it (width, value, flags, liveness, sources and rule-6 operands as argument indices, extension times)
 * with every event clock replaced by its rank among the arguments' clocks: a rail the window makes is later than all
 * of them, so the ranks decide every clock comparison the clone can make. absolute: the raw clocks and handles (the
 * snapshot a window's end compares, to see an argument changed). */
static void rp_key_put(cqe_rp_buf *o, uint64_t x) { cqe__rp_put(o, &x, sizeof x); }
static uint64_t rp_rank(uint64_t t, const uint64_t *ck, size_t nc, int absolute) {
  if (!t || absolute)
    return t;
  size_t lo = 0, hi = nc;
  while (lo < hi) {
    size_t mid = (lo + hi) / 2;
    if (ck[mid] < t)
      lo = mid + 1;
    else
      hi = mid;
  }
  return lo + 1;
}
static uint64_t rp_argref(int32_t d, const int32_t *hs, int n, int absolute) {
  if (absolute)
    return (uint32_t)d;
  for (int j = 0; j < n; ++j)
    if (hs[j] == d)
      return (uint64_t)j;
  return 0xffffffffULL;
}
void cqe__rp_argkey(const int32_t *hs, int n, int absolute, cqe_rp_buf *o) {
  uint64_t ck[64 * 5];
  size_t nc = 0;
  for (int i = 0; i < n && !absolute; ++i) {
    uint32_t h = (uint32_t)hs[i];
    if (hs[i] <= 0 || h > nrails)
      continue;
    tomb_t *t = rail_tomb(h);
    if (t) {
      ck[nc++] = t->a & TOMB_CLOCK_MAX;
      ck[nc++] = t->b & TOMB_CLOCK_MAX;
      continue;
    }
    rail_t *r = RL(h);
    ck[nc++] = r->t_create;
    ck[nc++] = r->t_write;
    if (rail_x(r)) {
      ck[nc++] = rail_x(r)->t_nd;
      ck[nc++] = rail_x(r)->t_meas;
      ck[nc++] = rail_x(r)->ry_t;
    }
  }
  for (size_t i = 1; i < nc; ++i) /* insertion sort: qsort may be the program's (rt_replay.h) */
    for (size_t j = i; j > 0 && ck[j - 1] > ck[j]; --j) {
      uint64_t t = ck[j];
      ck[j] = ck[j - 1];
      ck[j - 1] = t;
    }
  size_t u = 0;
  for (size_t i = 0; i < nc; ++i)
    if (ck[i] && (!u || ck[u - 1] != ck[i]))
      ck[u++] = ck[i];
  nc = u;
  for (int i = 0; i < n; ++i) {
    int al = -1;
    for (int j = 0; j < i && al < 0; ++j)
      if (hs[j] == hs[i])
        al = j;
    if (al >= 0) {
      rp_key_put(o, 0xa11a5000ULL | (uint64_t)al);
      continue;
    }
    uint32_t h = (uint32_t)hs[i];
    if (hs[i] <= 0 || h > nrails) {
      rp_key_put(o, 0xbad0000000000000ULL | h);
      continue;
    }
    tomb_t *t = rail_tomb(h);
    if (t) {
      rp_key_put(o, 0x70b0000000000000ULL | (t->a >> 48) | (uint64_t)tf_get(t) << 16);
      rp_key_put(o, rp_rank(t->a & TOMB_CLOCK_MAX, ck, nc, absolute));
      rp_key_put(o, rp_rank(t->b & TOMB_CLOCK_MAX, ck, nc, absolute));
      continue;
    }
    rail_t *r = RL(h);
    const rail_ext *rx = rail_x(r);
    rp_key_put(o, 0x5ec0000000000000ULL | r->wi | (uint64_t)tomb_flags(r) << 16 | (uint64_t)r->live << 40 |
                      (uint64_t)(rx != NULL) << 41 | (uint64_t)(rx && rx->r6_ops) << 42);
    rp_key_put(o, rp_rank(r->t_create, ck, nc, absolute));
    rp_key_put(o, rp_rank(r->t_write, ck, nc, absolute));
    rp_key_put(o, rail_nw(r));
    cqe__rp_put(o, rail_w(r), (size_t)rail_nw(r) * sizeof(uint64_t));
    uint32_t nd = rail_nd(r);
    rp_key_put(o, nd);
    const int32_t *deps = deps_of(r);
    for (uint32_t k = 0; k < nd; ++k)
      rp_key_put(o, rp_argref(deps[k], hs, n, absolute));
    if (rx) {
      const rail_ext *x = rx;
      rp_key_put(o, rp_rank(x->t_nd, ck, nc, absolute));
      rp_key_put(o, rp_rank(x->t_meas, ck, nc, absolute));
      rp_key_put(o, rp_rank(x->ry_t, ck, nc, absolute));
      rp_key_put(o, x->ry_ang);
      rp_key_put(o, x->r6_old ? rp_argref(x->r6_old, hs, n, absolute) : 0xfffffffeULL);
      rp_key_put(o, x->r6_nops);
      for (uint32_t k = 0; x->r6_ops && k < x->r6_nops; ++k)
        rp_key_put(o, rp_argref(x->r6_ops[k], hs, n, absolute));
      if (x->ry_t) {
        cqe__rp_put(o, x->ry_pre, (size_t)rail_nw(r) * sizeof *x->ry_pre);
        cqe__rp_put(o, x->ry_post, (size_t)rail_nw(r) * sizeof *x->ry_post);
      }
    }
  }
}

/* The rails base+1 .. nrails a window made, as its record holds them. -1: one refers to a rail outside the clone's
 * reach, or carries what a record does not (a non-diagonal gate's or measurement's time): not recordable. */
int cqe__rp_encode(uint32_t base, uint64_t c0, const int32_t *args, int nargs, cqe_rp_rails *out) {
  int ok = 1;
  cqe__rp_zero(out, sizeof *out);
  out->n = nrails - base;
  out->ticks = clock_ - c0;
  out->off = malloc((out->n ? out->n : 1) * sizeof *out->off);
  if (!out->off)
    abort();
  for (uint32_t i = 0; i < out->n && ok; ++i) {
    uint32_t h = base + 1 + i;
    out->off[i] = (uint32_t)out->blob.n;
    if (out->blob.n > UINT32_MAX - (1u << 24)) {
      ok = 0;
      break;
    }
    rp_rail e;
    cqe__rp_zero(&e, sizeof e);
    uint32_t m = map_peek(h);
    uint64_t la = 0;
    int fire = 0, load = cqe__bus_load_of((int32_t)h, &la, &fire);
    const rail_t *r = NULL;
    int32_t refs[66], *rf = refs;
    if (m & MAP_TOMB) {
      const tomb_t *t = &(*TOMB(m & ~MAP_TOMB));
      e.flags = tf_get(t) | RF_TOMB;
      e.wi = (uint16_t)(t->a >> 48);
      e.tc = rp_rel(t->a & TOMB_CLOCK_MAX, c0, &ok);
      e.tw = rp_rel(t->b & TOMB_CLOCK_MAX, c0, &ok);
    } else if (m) {
      r = &(*SLOT(m - 1));
      e.flags = tomb_flags(r) | (r->live ? RF_LIVE : 0);
      e.wi = r->wi;
      e.nw = rail_nw(r);
      e.ndeps = rail_nd(r);
      e.tc = rp_rel(r->t_create, c0, &ok);
      e.tw = rp_rel(r->t_write, c0, &ok);
      if (rail_x(r)) {
        const rail_ext *x = rail_x(r);
        e.flags |= RF_EXT;
        if (x->t_nd || x->t_meas || x->ry_t)
          ok = 0;
        e.r6_old = rp_enc(x->r6_old, base, args, nargs, &ok);
        if (x->r6_ops) {
          e.flags |= RF_R6OPS;
          e.nr6 = x->r6_nops;
        }
      }
      if ((size_t)e.ndeps + e.nr6 > sizeof refs / sizeof *refs) {
        rf = malloc(((size_t)e.ndeps + e.nr6) * sizeof *rf);
        if (!rf)
          abort();
      }
      const int32_t *deps = deps_of((rail_t *)r);
      for (uint32_t k = 0; k < e.ndeps; ++k)
        rf[k] = rp_enc(deps[k], base, args, nargs, &ok);
      for (uint32_t k = 0; k < e.nr6; ++k)
        rf[e.ndeps + k] = rp_enc(rail_x(r)->r6_ops[k], base, args, nargs, &ok);
    } else {
      ok = 0;
    }
    if (load)
      e.flags |= RF_LOAD | (fire ? RF_FIRE : 0);
    cqe__rp_put(&out->blob, &e, sizeof e);
    if (r)
      cqe__rp_put(&out->blob, rail_w((rail_t *)r), (size_t)e.nw * sizeof(uint64_t));
    size_t nref = (size_t)e.ndeps + e.nr6;
    cqe__rp_put(&out->blob, rf, nref * sizeof *rf);
    static const uint8_t zero[8];
    cqe__rp_put(&out->blob, zero, ((nref * 4 + 7) & ~(size_t)7) - nref * 4);
    if (load)
      cqe__rp_put(&out->blob, &la, sizeof la);
    if (rf != refs)
      free(rf);
  }
  if (!ok) {
    free(out->off);
    free(out->blob.p);
    cqe__rp_zero(out, sizeof *out);
    return -1;
  }
  cqe__rp_derive(out);
  return 0;
}

/* The exit event's view of a record: each live rail's value in hex. */
void cqe__rp_derive(cqe_rp_rails *rr) {
  free(rr->hexoff);
  free(rr->hexpool);
  rr->hexoff = malloc((rr->n ? rr->n : 1) * sizeof *rr->hexoff);
  if (!rr->hexoff)
    abort();
  size_t cap = 64, len = 0;
  char *pool = malloc(cap);
  if (!pool)
    abort();
  for (uint32_t i = 0; i < rr->n; ++i) {
    const rp_rail *e = rp_hdr(rr, i);
    rr->hexoff[i] = UINT32_MAX;
    if (!(e->flags & RF_LIVE) || (e->flags & RF_TOMB))
      continue;
    cqe_val v = {0, 'i', e->nw, (uint64_t *)rp_words(e)};
    char *hx = cqe__hexa(&v);
    size_t need = 1;
    while (hx[need - 1])
      ++need;
    while (len + need > cap) {
      cap *= 2;
      pool = realloc(pool, cap);
      if (!pool)
        abort();
    }
    cqe__rp_cpy(pool + len, hx, need);
    rr->hexoff[i] = (uint32_t)len;
    len += need;
    free(hx);
  }
  rr->hexpool = pool;
}

/* The tampered-record self-check (CQE_REPLAY_TAMPER, rt_replay.c): bit 0 of the first live rail's value flipped. */
int cqe__rp_tamper(cqe_rp_rails *rr) {
  for (uint32_t i = 0; i < rr->n; ++i) {
    rp_rail *e = (rp_rail *)(void *)(rr->blob.p + rr->off[i]);
    if ((e->flags & RF_LIVE) && !(e->flags & RF_TOMB) && e->nw) {
      ((uint64_t *)(void *)(e + 1))[0] ^= 1;
      cqe__rp_derive(rr);
      return 1;
    }
  }
  return 0;
}

/* A replayed call: its rails are base+1 .. base+n, untouched (one block); the handle counter and the clock advance as
 * the real run advanced them. Returns base. */
uint32_t cqe__rp_apply(const cqe_rp_rails *rr, const int32_t *args, int nargs) {
  uint32_t base = nrails;
  if (nrails + (uint64_t)rr->n + 1 >= CQE_RAIL_LIMIT) {
    fprintf(stderr, "cq: chk-core: rail handles exhausted (limit 0x%x, the bus handle)\n", (unsigned)CQE_RAIL_LIMIT);
    abort();
  }
  if (rr->n) {
    if (rp_nblocks == rp_capblocks) {
      rp_capblocks = rp_capblocks ? 2 * rp_capblocks : 1024;
      rp_blocks = realloc(rp_blocks, rp_capblocks * sizeof *rp_blocks);
      if (!rp_blocks)
        abort();
    }
    if (rp_nargpool + (size_t)nargs > rp_capargpool) {
      while (rp_nargpool + (size_t)nargs > rp_capargpool)
        rp_capargpool = rp_capargpool ? 2 * rp_capargpool : 4096;
      rp_argpool = realloc(rp_argpool, rp_capargpool * sizeof *rp_argpool);
      if (!rp_argpool)
        abort();
    }
    if (rp_nargpool + (size_t)nargs > UINT32_MAX) {
      fprintf(stderr, "cq: chk-core: replay argument pool exhausted\n");
      abort();
    }
    if (nargs)
      cqe__rp_cpy(rp_argpool + rp_nargpool, args, (size_t)nargs * sizeof *rp_argpool);
    uint32_t below = rp_nblocks ? rp_blocks[rp_nblocks - 1].below + rp_blocks[rp_nblocks - 1].n : 0;
    rp_blocks[rp_nblocks++] = (rp_block){base, rr->n, below, (uint32_t)rp_nargpool, clock_, rr};
    rp_nargpool += (size_t)nargs;
  }
  nrails += rr->n;
  clock_ += rr->ticks;
  clock_check();
  return base;
}

static const rp_block *rp_find(uint32_t h) {
  uint32_t d = 0;
  const rp_block *b = NULL;
  return hclass(h, &d, &b) == 2 ? b : NULL;
}

/* Block rail h made from its record, exactly as the real run left it; its map entry. 0: h is in no block. */
static uint32_t rp_materialize(uint32_t h) {
  const rp_block *b = rp_find(h);
  if (!b)
    return 0;
  const rp_rail *e = rp_hdr(b->rr, h - b->base - 1);
  ++rp_nmat;
  if (e->flags & RF_TOMB) {
    uint32_t t = tomb_n++;
    if (tomb_n > MAP_TOMB) {
      fprintf(stderr, "cq: chk-core: rail tombstones exhausted\n");
      abort();
    }
    DIR_GROW(tomb_dir, t, TOMB_BITS);
    tomb_t *tb = &(*TOMB(t));
    tb->a = rp_abs(e->tc, b->c0) | (uint64_t)e->wi << 48;
    tb->b = rp_abs(e->tw, b->c0);
    tf_set(tb, e->flags & 0xffff);
    map_put(h, t | MAP_TOMB);
    return t | MAP_TOMB;
  }
  uint32_t s, f = e->flags;
  rail_t *r = pool_take(&s);
  r->wi = e->wi; /* e->nw is the token's word count (cqe__rp_encode) */
  if (e->nw > 1)
    r->val.wide = xcalloc(e->nw, sizeof *r->val.wide);
  cqe__rp_cpy(rail_w(r), rp_words(e), (size_t)e->nw * sizeof(uint64_t));
  r->t_create = rp_abs(e->tc, b->c0);
  r->t_write = rp_abs(e->tw, b->c0);
  r->known = f >> TF_KNOWN & 1;
  r->measured = f >> TF_MEASURED & 1;
  r->frozen = f >> TF_FROZEN & 1;
  r->written = f >> 3 & 1;
  r->seed = f >> 4 & 1;
  r->busz = f >> TF_BUSZ & 1;
  r->store_kept = f >> TF_STORE_KEPT & 1;
  r->image = f >> TF_IMAGE & 1;
  r->r6 = f >> TF_R6 & 1;
  r->load_copy = f >> TF_LOAD_COPY & 1;
  r->role = f >> TF_ROLE & 7;
  r->fenv = f >> TF_FENV & 3;
  r->live = (f & RF_LIVE) != 0;
  const int32_t *refs = rp_refs(e);
  for (uint32_t k = 0; k < e->ndeps; ++k)
    deps_append(r, cqe__rp_dec_handle(refs[k], b->base, RP_ARGS(b)));
  if (f & RF_EXT) {
    rail_ext *x = ext_of(r);
    x->r6_old = cqe__rp_dec_handle(e->r6_old, b->base, RP_ARGS(b));
    if (f & RF_R6OPS) {
      x->r6_ops = malloc((e->nr6 ? e->nr6 : 1) * sizeof *x->r6_ops);
      if (!x->r6_ops)
        abort();
      for (uint32_t k = 0; k < e->nr6; ++k)
        x->r6_ops[k] = cqe__rp_dec_handle(refs[e->ndeps + k], b->base, RP_ARGS(b));
      x->r6_nops = e->nr6;
    }
  }
  map_put(h, s + 1);
  return s + 1;
}

/* The load that made block rail h (rt_bus.c asks when its own table has no entry). */
int cqe__rp_block_load(int32_t h, uint64_t *addr, int *fire) {
  if (h <= 0 || !rp_nblocks)
    return 0;
  const rp_block *b = rp_find((uint32_t)h);
  if (!b)
    return 0;
  const rp_rail *e = rp_hdr(b->rr, (uint32_t)h - b->base - 1);
  if (!(e->flags & RF_LOAD))
    return 0;
  cqe__rp_cpy(addr, rp_loadaddr(e), sizeof *addr);
  *fire = (e->flags & RF_FIRE) != 0;
  return 1;
}

/* An untouched rail of block b at the exit event: its row, read from the record (the rail is not made). */
static int rp_exit_rail(const rp_block *b, uint32_t h) {
  uint32_t i = h - b->base - 1;
  const rp_rail *e = rp_hdr(b->rr, i);
  if (!(e->flags & RF_LIVE) || (e->flags & RF_TOMB))
    return 0;
  uint32_t f = e->flags;
  rail_t r;
  cqe__rp_zero(&r, sizeof r);
  r.wi = e->wi;
  r.measured = f >> TF_MEASURED & 1;
  r.frozen = f >> TF_FROZEN & 1;
  r.written = f >> 3 & 1;
  r.seed = f >> 4 & 1;
  r.store_kept = f >> TF_STORE_KEPT & 1;
  r.image = f >> TF_IMAGE & 1;
  r.r6 = f >> TF_R6 & 1;
  r.role = f >> TF_ROLE & 7;
  r.fenv = f >> TF_FENV & 3;
  r.t_write = rp_abs(e->tw, b->c0);
  int32_t dbuf[64], *deps = dbuf;
  if (e->ndeps > 64) {
    deps = malloc(e->ndeps * sizeof *deps);
    if (!deps)
      abort();
  }
  const int32_t *refs = rp_refs(e);
  for (uint32_t k = 0; k < e->ndeps; ++k)
    deps[k] = cqe__rp_dec_handle(refs[k], b->base, RP_ARGS(b));
  const char *role = exit_role_r(&r, deps, e->ndeps);
  if (deps != dbuf)
    free(deps);
  exit_feed(h, wtab[e->wi], b->rr->hexpool + b->rr->hexoff[i], role, f >> TF_KNOWN & 1);
  return 1;
}

/* Rail i of record rr at the exit event, read-only: 0 when it is not live at the record's end; else its width, value
 * and known flag in row, its role as exit_role_r gives it when no source received a gate after the write (no deps),
 * and its source refs as the record holds them. */
static int rp_exit_key(const cqe_rp_rails *rr, uint32_t i, live_row *row, const int32_t **refs, uint32_t *nrefs) {
  const rp_rail *e = rp_hdr(rr, i);
  if (!(e->flags & RF_LIVE) || (e->flags & RF_TOMB))
    return 0;
  uint32_t f = e->flags;
  rail_t r;
  cqe__rp_zero(&r, sizeof r);
  r.wi = e->wi;
  r.measured = f >> TF_MEASURED & 1;
  r.frozen = f >> TF_FROZEN & 1;
  r.written = f >> 3 & 1;
  r.seed = f >> 4 & 1;
  r.store_kept = f >> TF_STORE_KEPT & 1;
  r.image = f >> TF_IMAGE & 1;
  r.r6 = f >> TF_R6 & 1;
  r.role = f >> TF_ROLE & 7;
  r.fenv = f >> TF_FENV & 3;
  *row = (live_row){0, 1, 0, wtab[e->wi], exit_role_r(&r, NULL, 0), f >> TF_KNOWN & 1, rr->hexpool + rr->hexoff[i]};
  *refs = rp_refs(e);
  *nrefs = e->ndeps;
  return 1;
}
