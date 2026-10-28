/* Checker core (cq-w0-chk-core): the rail store of the §6.1 classical basis-state evaluator, the
 * JSONL trace, violations, and the cqe.h API that families use. Symbol handling (the stub entry
 * cqe_dispatch, core-gate semantics, the template registry and parser) is in dispatch.c.
 *
 * Rails. A handle names one rail for the whole run; handles are never reused (1, 2, 3, ...). A rail
 * has a width token ("i32", "f80", ...), a basis value (cqe_val, little-endian 64-bit words, bits
 * above the width zero), a liveness state and its known-basis flag (CR §0, CLAUDE.md "The §6
 * checker"): a rail is known when it is in a known classical basis state, so cqrt_free may reset it.
 * Known: a seed (cqrt_alloc), a seed after an uncontrolled xorc, a template result or copy computed
 * only from known rails, a measured rail, and a rail an XOR-into write (template _unc, copy,
 * and/or/xor_i1) returned to 0 with no non-diagonal gate (Ry) on the target or any source after
 * the target's or the sources' creation (dispatch.c, zero_rule). A rotated rail is not known.
 *
 * Trace. One JSON object per line, to the file named by $CQE_TRACE (stderr when unset), flushed
 * per line so a crash keeps every event before it. The frozen events of cq-arch are written with
 * their frozen fields; some carry additive fields (documented at each writer). The exit event is
 * written by an atexit handler registered before any other runtime handler, so it comes last.
 * Under the batch driver (run.py) every sample is a forked child of one runner process (shots, at the
 * end of this file); the exit event and every family's end-of-shot handler then run once per sample,
 * in its child, and the runner itself logs only the shot frames.
 *
 * Exit roles (event "exit", field "role" of each live rail): measured, abort, tape, qram, frozen
 * (rotated, not measured), kept_entangled (cq-arch A4: a rail one of whose direct sources received
 * a non-diagonal gate or a measurement after the rail was written), seed (an alloc never written
 * since), garbage (anything else).
 */
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <unistd.h>

#include "cqe.h"

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
static int shot_muted; /* a batch runner's own end (shots, end of file): nothing more is logged */

static void at_exit_handler(void);

void cqe__init(void) {
  if (inited)
    return;
  inited = 1;
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
  if (shot_muted)
    return;
  fputs(json_object, trace_f);
  fputc('\n', trace_f);
  fflush(trace_f);
}

/* printf-style log of one line. */
void cqe__logf(const char *fmt, ...) {
  cqe__init();
  if (shot_muted)
    return;
  va_list ap;
  va_start(ap, fmt);
  vfprintf(trace_f, fmt, ap);
  va_end(ap);
  fputc('\n', trace_f);
  fflush(trace_f);
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
  uint8_t live, known, measured, frozen, written, seed, role;   /* role: 0 none, 1 abort, 2 tape, 3 qram */
  uint64_t t_create, t_write, t_nd, t_meas;                       /* event clock; 0 = never */
  int32_t *deps;
  uint32_t ndeps, capdeps;
} rail_t;

#define CQE_RAIL_LIMIT 0x51000000u /* rail handles stay below rt-mem's QRAM bus handles (cq-lxv) */
static rail_t *rails; /* rails[h], h >= 1 */
static uint32_t nrails, caprails;
static uint64_t clock_;

uint64_t cqe__tick(void) { return ++clock_; }
uint32_t cqe__nrails_peek(void) { return nrails; }

int32_t cqe__new(const char *w, const cqe_val *init, int known, int seed) {
  cqe__init();
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
    /* rt-mem numbers QRAM buses from 0x51000000 and its synthetic exit ids from 0x5A000000 */
    fprintf(stderr, "cq: chk-core: rail handles exhausted (limit 0x%x, below rt-mem's bus range)\n",
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
void cqe__setrole(int32_t h, int role) { rails[h].role = (uint8_t)role; }

void cqe__mark_written(int32_t h) {
  rails[h].written = 1;
  rails[h].t_write = cqe__tick();
}
void cqe__mark_nd(int32_t h) {
  rails[h].frozen = 1;
  rails[h].t_nd = cqe__tick();
}
void cqe__mark_measured(int32_t h) {
  rails[h].measured = 1;
  rails[h].known = 1;
  rails[h].t_meas = cqe__tick();
}
void cqe__add_dep(int32_t h, int32_t src) {
  rail_t *r = &rails[h];
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

void cqe__free(int32_t h) { rails[h].live = 0; }

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
  if (r->role == 3)
    return "qram";
  if (r->frozen)
    return "frozen";
  for (uint32_t i = 0; i < r->ndeps; ++i) {
    rail_t *s = &rails[r->deps[i]];
    if ((s->t_nd && s->t_nd > r->t_write) || (s->t_meas && s->t_meas > r->t_write))
      return "kept_entangled";
  }
  if (r->seed && !r->written)
    return "seed";
  return "garbage";
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
  APPEND("{\"ev\":\"exit\",\"live\":[");
  int first = 1;
  for (uint32_t h = 1; h <= nrails; ++h) {
    if (!rails[h].live)
      continue;
    char *hx = cqe__hexa(&rails[h].v);
    APPEND("%s{\"h\":%u,\"w\":\"%s\",\"v\":\"%s\",\"role\":\"%s\"}", first ? "" : ",", h, rails[h].w, hx,
           exit_role((int32_t)h));
    free(hx);
    first = 0;
  }
  APPEND("],\"violations\":%lu}", nviolations);
#undef APPEND
  cqe_log(buf);
  free(buf);
  if (trace_f && trace_f != stderr)
    fclose(trace_f);
  trace_f = stderr;
}

/* ---- shots (cq-e2i9): one runner process per batch, one forked child per sample ---------------
 *
 * run.py renders the driver (drivers.driver_source) with before_call "if (!cqe__shot_begin(CQD_SAMPLE)) {"
 * and after_call "cqe__shot_end(); }". The process (the runner) runs the setup once and then, for every
 * record of the sample file, forks: the child is the shot. It runs the record's call from the runner's
 * post-setup state and ends through cqe__shot_end (exit(0): every atexit handler runs and the core's
 * exit event closes the shot, as a process of its own did before). All per-sample state (rails, the
 * handle counter, known flags, the violation count, logs, fenv, the theta schedule, the families'
 * tables and end-of-shot handlers, the program's own globals and heap, the setup's locals) belongs to
 * the child and goes with it, so nothing of sample i is visible in sample i+1, whatever sample i did
 * (a violation, a dirty free, a signal, a timeout). This is the C oracle's scheme (cqo_rt.c).
 *
 * Frames, written by the runner around each shot (private to chk-core; run.py removes them):
 *   {"ev":"shot","k":<k>}
 *   {"ev":"shot_end","k":<k>,"code":<c>,"timeout":<0|1>,"stdout":"..","stderr":".."}
 * k = $CQE_SHOT_BASE + the record index. code is the child's exit status, or minus the signal that
 * ended it. stdout is everything the child wrote to its stdout; stderr is the last 4000 bytes of
 * its stderr, only for a child that did not exit 0 (and only when the trace is not stderr).
 * Environment: $CQE_SHOT_DIR (a directory for the capture files; a fresh one under $TMPDIR when unset),
 * $CQE_SHOT_TIMEOUT (seconds, default 30: the child's ITIMER_REAL; the runner SIGKILLs a child still
 * alive after twice that plus a second, and either is reported with "timeout":1), $CQE_THETA_ALL (the
 * theta schedules of the batch: "@<k>" lines, each followed by sample k's $CQE_THETA lines; a shot
 * with no block has no schedule; without $CQE_THETA_ALL every shot keeps $CQE_THETA as it is). */

void cqe__theta_use(const char *text, size_t n); /* dispatch.c */

static pid_t shot_runner; /* the runner's pid; 0 before its first shot */
static char shot_dir[1024], shot_out[1100], shot_err[1100];
static int shot_own_dir;
static long shot_base;
static double shot_timeout = 30.0;
static volatile sig_atomic_t shot_alarm;
static char *theta_all;          /* $CQE_THETA_ALL's text */
static int theta_all_set;
typedef struct { long k; const char *p; size_t n; } theta_block;
static theta_block *theta_blocks;
static size_t theta_nblocks;

static void shot_on_alarm(int sig) {
  (void)sig;
  shot_alarm = 1;
}

/* The runner's end: registered after every constructor's atexit, so it runs first and mutes the
 * families' and the core's end-of-shot logging, which belongs to the children. */
static void shot_runner_exit(void) {
  if (getpid() != shot_runner)
    return;
  shot_muted = 1;
  if (shot_own_dir) {
    unlink(shot_out);
    unlink(shot_err);
    rmdir(shot_dir);
  }
}

static void shot_timer(double s) {
  struct itimerval it;
  memset(&it, 0, sizeof it);
  if (s > 0) {
    it.it_value.tv_sec = (time_t)s;
    it.it_value.tv_usec = (suseconds_t)((s - (double)(time_t)s) * 1e6);
    if (!it.it_value.tv_sec && !it.it_value.tv_usec)
      it.it_value.tv_usec = 1;
  }
  setitimer(ITIMER_REAL, &it, NULL);
}

/* The file at path (its last `tail` bytes when tail > 0) as a JSON string body (heap); "" when empty. */
static char *shot_slurp_json(const char *path, long tail) {
  struct stat st;
  if (stat(path, &st) != 0 || st.st_size == 0)
    return xcalloc(1, 1);
  FILE *f = fopen(path, "rb");
  if (!f)
    return xcalloc(1, 1);
  long n = (long)st.st_size, from = (tail > 0 && n > tail) ? n - tail : 0;
  fseek(f, from, SEEK_SET);
  n -= from;
  unsigned char *b = xcalloc((size_t)n + 1, 1);
  n = (long)fread(b, 1, (size_t)n, f);
  fclose(f);
  char *o = xcalloc(6 * (size_t)n + 1, 1), *p = o;
  for (long i = 0; i < n; ++i) {
    unsigned char c = b[i];
    if (c == '"' || c == '\\') {
      *p++ = '\\';
      *p++ = (char)c;
    } else if (c < 0x20 || c >= 0x7f) { /* bytes, not UTF-8: every non-ASCII byte as \u00XX */
      p += sprintf(p, "\\u%04x", c);
    } else {
      *p++ = (char)c;
    }
  }
  free(b);
  return o;
}

static void shot_die(const char *what) {
  fprintf(stderr, "cq: chk-core: %s: %s\n", what, strerror(errno));
  _exit(98);
}

static void theta_all_load(const char *path) {
  theta_all_set = 1;
  FILE *f = fopen(path, "rb");
  if (!f)
    shot_die("cannot open $CQE_THETA_ALL");
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  theta_all = xcalloc((size_t)n + 1, 1);
  if (fread(theta_all, 1, (size_t)n, f) != (size_t)n)
    shot_die("cannot read $CQE_THETA_ALL");
  fclose(f);
  size_t cap = 0;
  for (char *p = theta_all; *p;) {
    char *nl = strchr(p, '\n');
    char *end = nl ? nl + 1 : p + strlen(p);
    if (*p == '@') {
      if (theta_nblocks == cap) {
        cap = cap ? 2 * cap : 256;
        theta_blocks = realloc(theta_blocks, cap * sizeof *theta_blocks);
        if (!theta_blocks)
          abort();
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

static void shot_setup(void) {
  shot_runner = getpid();
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
  shot_base = b && *b ? strtol(b, NULL, 10) : 0;
  const char *to = getenv("CQE_SHOT_TIMEOUT");
  if (to && *to)
    shot_timeout = strtod(to, NULL);
  const char *th = getenv("CQE_THETA_ALL");
  if (th && *th)
    theta_all_load(th);
  struct sigaction sa;
  memset(&sa, 0, sizeof sa);
  sa.sa_handler = shot_on_alarm; /* no SA_RESTART: waitpid returns EINTR */
  sigemptyset(&sa.sa_mask);
  sigaction(SIGALRM, &sa, NULL);
  atexit(shot_runner_exit);
}

/* before_call: 0 in the child (run the call), 1 in the runner once the child has ended. */
int cqe__shot_begin(int idx) {
  cqe__init();
  if (!shot_runner)
    shot_setup();
  long k = shot_base + idx;
  cqe__logf("{\"ev\":\"shot\",\"k\":%ld}", k);
  fflush(NULL);
  pid_t pid = fork();
  if (pid < 0)
    shot_die("fork");
  if (pid == 0) {
    signal(SIGALRM, SIG_DFL);
    int fd = open(shot_out, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd >= 0) {
      dup2(fd, 1);
      close(fd);
    }
    if (trace_f != stderr) {
      fd = open(shot_err, O_WRONLY | O_CREAT | O_TRUNC, 0600);
      if (fd >= 0) {
        dup2(fd, 2);
        close(fd);
      }
    }
    if (theta_all_set) {
      const theta_block *tb = NULL;
      /* blocks are written in k order; a binary search finds k's */
      size_t lo = 0, hi = theta_nblocks;
      while (lo < hi) {
        size_t mid = (lo + hi) / 2;
        if (theta_blocks[mid].k < k)
          lo = mid + 1;
        else
          hi = mid;
      }
      if (lo < theta_nblocks && theta_blocks[lo].k == k)
        tb = &theta_blocks[lo];
      cqe__theta_use(tb ? tb->p : NULL, tb ? tb->n : 0);
    }
    shot_timer(shot_timeout);
    return 0;
  }
  shot_alarm = 0;
  shot_timer(2 * shot_timeout + 1);
  int st = 0, killed = 0;
  for (;;) {
    pid_t r = waitpid(pid, &st, 0);
    if (r == pid)
      break;
    if (r < 0 && errno == EINTR) {
      if (shot_alarm && !killed) {
        kill(pid, SIGKILL);
        killed = 1;
      }
      continue;
    }
    shot_die("waitpid");
  }
  shot_timer(0);
  int code = -1, timeout = 0;
  if (WIFEXITED(st)) {
    code = WEXITSTATUS(st);
  } else if (WIFSIGNALED(st)) {
    code = -WTERMSIG(st);
    timeout = killed || WTERMSIG(st) == SIGALRM;
  }
  char *out = shot_slurp_json(shot_out, 0);
  char *err = (code && trace_f != stderr) ? shot_slurp_json(shot_err, 4000) : xcalloc(1, 1);
  cqe__logf("{\"ev\":\"shot_end\",\"k\":%ld,\"code\":%d,\"timeout\":%d,\"stdout\":\"%s\",\"stderr\":\"%s\"}", k,
            code, timeout, out, err);
  free(out);
  free(err);
  return 1;
}

/* after_call: the shot is over; exit runs every end-of-shot handler, the core's exit event last. */
void cqe__shot_end(void) { exit(0); }
