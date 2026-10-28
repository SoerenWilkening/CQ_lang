/* cqo_rt.c: runtime of the C oracle (cq-w0-chk-oracle). Linked with the program instrumented by
 * OracleInstr.cpp and a driver from drivers.driver_source(spec, samples, main_name="__cqo_drv_main",
 * before_call="if (__cqo_sample_begin(CQD_SAMPLE)) {", after_call="__cqo_sample_end(); }").
 * C17, compiled separately, never instrumented.
 *
 *   prog <trace> <status> <timeout_ms> <tripcap> [<subst>]
 *
 * The driver's setup runs once; each sample's call runs in its own forked child from that state, so a
 * trap, an abort or a hang ends that sample only. The child appends `<index>\t<event JSON>` lines to
 * <trace> and `<index>\t<note>` lines to <status>; the parent adds `<index>\twait exited N|signaled
 * S|timeout`. Notes: `noreturn <callee>`, `raise <sig>`, `ub unreachable <fn>`, `ub oob-atomic`,
 * `tripcap`, `crash <signal> addr=<a>`, `oob-load`, `oob-store`, `cap <loop>` (a quantum-exit loop or
 * quantum-depth recursion stopped after K trips: the sample ends there, not a failure; cq-8ay),
 * `internal <why>`.
 * The cutoff records of cq-arch T2 go to <trace> as `{"ev":"kloop","loop","act","n","capped"[,"cut",
 * "mcut"]}` lines (oracle.py moves them to outputs["loops"]; they are not trace events).
 * <subst> lines `<index> <fn> <site> <period> <occ> <nwords> <hex w>...` replace the register value at a
 * cq_theta site (cq-6m2, cq-arch Z4): the r-th reach (0-based) of site <fn>:<site> in sample <index>
 * takes the line whose <occ> is r mod <period>; a site with no line keeps its value (the identity).
 * Values in events are hex bit patterns, "0x" plus lowercase digits without leading zeros. */
#define _DARWIN_C_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <fenv.h>
#include <pthread.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../rt/cq_standin.h"


/* ------------------------------------------------------------------ output */
static int trace_fd = -1, status_fd = -1;
static long cur_sample = -1;

/* A worker's output buffers (shared with the server, which writes out what a dead worker left; n
 * counts whole lines only). */
#define OBUF_CAP ((size_t)1 << 20)
typedef struct { volatile size_t n; char b[OBUF_CAP]; } obuf;
static obuf *ob_trace, *ob_status; /* non-null in a worker */

static void write_all(int fd, const char *p, size_t n) {
    while (n) {
        ssize_t r = write(fd, p, n);
        if (r < 0) { if (errno == EINTR) continue; return; }
        p += r, n -= (size_t)r;
    }
}

static void ob_flush(obuf *o, int fd) {
    size_t n = o->n;
    if (n) write_all(fd, o->b, n);
    o->n = 0;
}

static void out_line(int fd, const char *s) {
    char buf[4096];
    int n = snprintf(buf, sizeof buf, "%ld\t%s\n", cur_sample, s);
    if (n < 0) return;
    if (n >= (int)sizeof buf) n = sizeof buf - 1, buf[n - 1] = '\n';
    if (fd < 0) return;
    obuf *o = fd == trace_fd ? ob_trace : fd == status_fd ? ob_status : 0;
    if (!o) { write_all(fd, buf, (size_t)n); return; }
    if (o->n + (size_t)n > OBUF_CAP) ob_flush(o, fd);
    memcpy(o->b + o->n, buf, (size_t)n);
    o->n += (size_t)n;
}

static void note(const char *fmt, ...) {
    char s[1024];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(s, sizeof s, fmt, ap);
    va_end(ap);
    out_line(status_fd, s);
}

/* bits of a little-endian buffer as "0x..." */
static void hexbits(char *out, const unsigned char *p, unsigned bits) {
    unsigned nbytes = (bits + 7) / 8;
    unsigned char b[64];
    if (nbytes > sizeof b) nbytes = sizeof b;
    memcpy(b, p, nbytes);
    if (bits % 8) b[nbytes - 1] &= (unsigned char)((1u << (bits % 8)) - 1);
    char *o = out;
    *o++ = '0', *o++ = 'x';
    int started = 0;
    for (int i = (int)nbytes - 1; i >= 0; --i) {
        static const char hx[] = "0123456789abcdef";
        int hi = b[i] >> 4, lo = b[i] & 15;
        if (started || hi) *o++ = hx[hi], started = 1;
        if (started || lo) *o++ = hx[lo], started = 1;
    }
    if (!started) *o++ = '0';
    *o = 0;
}

static void jsonstr(char *out, size_t cap, const char *s) {
    size_t k = 0;
    out[k++] = '"';
    for (; *s && k + 3 < cap; ++s) {
        if (*s == '"' || *s == '\\') out[k++] = '\\';
        out[k++] = *s;
    }
    out[k++] = '"';
    out[k] = 0;
}

/* ------------------------------------------------------------------ object table (CR §6) */
typedef struct { uintptr_t lo, hi; } obj;
typedef struct { obj *v; size_t n, cap; } objvec;
static objvec stack_objs, heap_objs, global_objs;

#define OV_CAP ((size_t)1 << 26) /* entries reserved per table (address space only) */
static void ov_push(objvec *t, uintptr_t lo, uintptr_t hi) {
    if (!t->v) {
        void *m = mmap(0, OV_CAP * sizeof(obj), PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
        if (m == MAP_FAILED) { fprintf(stderr, "cqo: mmap\n"); _exit(2); }
        t->v = m, t->cap = OV_CAP;
    }
    if (t->n == t->cap) { fprintf(stderr, "cqo: more than %zu objects\n", (size_t)OV_CAP); _exit(2); }
    t->v[t->n].lo = lo, t->v[t->n].hi = hi, t->n++;
}

static const obj *ov_find(const objvec *t, uintptr_t a) {
    for (size_t i = t->n; i-- > 0;)
        if (a >= t->v[i].lo && a < t->v[i].hi) return &t->v[i];
    return 0;
}

static const obj *find_obj(uintptr_t a) {
    const obj *o = ov_find(&stack_objs, a);
    if (!o) o = ov_find(&heap_objs, a);
    if (!o) o = ov_find(&global_objs, a);
    return o;
}

static int in_bounds(const void *p, uint64_t n) {
    uintptr_t a = (uintptr_t)p;
    if (n == 0) return 1;
    const obj *o = find_obj(a);
    return o && a + n <= o->hi && a + n >= a;
}


static unsigned oob_loads, oob_stores;

void __cqo_global(void *p, uint64_t n) { ov_push(&global_objs, (uintptr_t)p, (uintptr_t)p + n); }
uint64_t __cqo_mark(void) { return stack_objs.n; }
void __cqo_release(uint64_t m) { if (m < stack_objs.n) stack_objs.n = m; }
void __cqo_alloca(void *p, uint64_t n) {
    ov_push(&stack_objs, (uintptr_t)p, (uintptr_t)p + n);
    memset(p, 0, n); /* an uninitialized local reads 0 */
}

/* An object of the current frame that already holds its value: a byval parameter copy. */
void __cqo_object(void *p, uint64_t n) { ov_push(&stack_objs, (uintptr_t)p, (uintptr_t)p + n); }

/* va_start(ap) on x86-64 SysV: ap = {i32 gp_offset, i32 fp_offset, ptr overflow_arg_area,
 * ptr reg_save_area}. The register save area (6 GP + 8 SSE registers) and the caller's stack-passed
 * variadic arguments (`ovf` bytes, OracleInstr.cpp variadicStackBytes) are objects of this frame. */
int64_t __cqo_va_bytes;
void __cqo_va_start(void *ap, int64_t ovf) {
    void *overflow, *regs;
    memcpy(&overflow, (char *)ap + 8, sizeof overflow);
    memcpy(&regs, (char *)ap + 16, sizeof regs);
    ov_push(&stack_objs, (uintptr_t)regs, (uintptr_t)regs + 176);
    if (ovf > 0) ov_push(&stack_objs, (uintptr_t)overflow, (uintptr_t)overflow + (uint64_t)ovf);
}

void __cqo_zero(void *p, int64_t n) {
    const obj *o = find_obj((uintptr_t)p);
    if (!o) return;
    uintptr_t a = (uintptr_t)p, e = n < 0 ? o->hi : a + (uint64_t)n;
    if (e > o->hi) e = o->hi;
    memset(p, 0, e - a);
}

/* The object an access belongs to: the one containing its base pointer, else the one containing the
 * accessed address. NULL: no object (every byte reads 0, stores are dropped). */
static const obj *access_obj(const void *base, const void *p) {
    const obj *o = base ? find_obj((uintptr_t)base) : 0;
    return o ? o : find_obj((uintptr_t)p);
}

static int inside(const obj *o, uintptr_t a, uint64_t n) {
    return o && a >= o->lo && a + n <= o->hi && a + n >= a;
}

void __cqo_load(const void *p, uint64_t n, void *dst, const void *base) {
    const obj *o = access_obj(base, p);
    uintptr_t a = (uintptr_t)p;
    if (inside(o, a, n)) { memcpy(dst, p, n); return; }
    unsigned char *d = dst;
    for (uint64_t i = 0; i < n; ++i) d[i] = inside(o, a + i, 1) ? ((const unsigned char *)p)[i] : 0;
    if (oob_loads++ < 8) note("oob-load");
}

void __cqo_store(void *p, uint64_t n, const void *src, const void *base) {
    const obj *o = access_obj(base, p);
    uintptr_t a = (uintptr_t)p;
    if (inside(o, a, n)) { memcpy(p, src, n); return; }
    for (uint64_t i = 0; i < n; ++i)
        if (inside(o, a + i, 1)) ((unsigned char *)p)[i] = ((const unsigned char *)src)[i];
    if (oob_stores++ < 8) note("oob-store");
}

void __cqo_require(const void *p, uint64_t n) {
    if (!in_bounds(p, n)) { note("ub oob-atomic"); _exit(96); }
}

void __cqo_imemset(void *p, uint8_t v, uint64_t n, const void *base) {
    const obj *o = access_obj(base, p);
    uintptr_t a = (uintptr_t)p;
    if (inside(o, a, n)) { memset(p, v, n); return; }
    for (uint64_t i = 0; i < n; ++i)
        if (inside(o, a + i, 1)) ((unsigned char *)p)[i] = v;
    if (oob_stores++ < 8) note("oob-store");
}

void __cqo_imemmove(void *d, const void *s, uint64_t n, const void *dbase, const void *sbase) {
    const obj *od = access_obj(dbase, d), *os = access_obj(sbase, s);
    if (inside(od, (uintptr_t)d, n) && inside(os, (uintptr_t)s, n)) { memmove(d, s, n); return; }
    unsigned char *tmp = malloc(n ? n : 1);
    __cqo_load(s, n, tmp, sbase);
    __cqo_store(d, n, tmp, dbase);
    free(tmp);
}

/* library entry points (the declarations they replace have no body in the module) */
void *__cqo_memcpy(void *d, const void *s, size_t n) { __cqo_imemmove(d, s, n, d, s); return d; }
void *__cqo_memmove(void *d, const void *s, size_t n) { __cqo_imemmove(d, s, n, d, s); return d; }
void *__cqo_memset(void *d, int v, size_t n) { __cqo_imemset(d, (uint8_t)v, n, d); return d; }
void *__cqo___memcpy_chk(void *d, const void *s, size_t n, size_t dn) { (void)dn; __cqo_imemmove(d, s, n, d, s); return d; }
void *__cqo___memmove_chk(void *d, const void *s, size_t n, size_t dn) { (void)dn; __cqo_imemmove(d, s, n, d, s); return d; }
void *__cqo___memset_chk(void *d, int v, size_t n, size_t dn) { (void)dn; __cqo_imemset(d, (uint8_t)v, n, d); return d; }
void __cqo_bzero(void *d, size_t n) { __cqo_imemset(d, 0, n, d); }
int __cqo_memcmp(const void *a, const void *b, size_t n) {
    for (size_t i = 0; i < n; ++i) {
        unsigned char x, y;
        __cqo_load((const unsigned char *)a + i, 1, &x, a);
        __cqo_load((const unsigned char *)b + i, 1, &y, b);
        if (x != y) return x < y ? -1 : 1;
    }
    return 0;
}
int __cqo_bcmp(const void *a, const void *b, size_t n) { return __cqo_memcmp(a, b, n) != 0; }

/* heap: every block zeroed (an indeterminate cell reads 0), realloc growth too */
static void heap_add(void *p, size_t n) { ov_push(&heap_objs, (uintptr_t)p, (uintptr_t)p + n); }
static size_t heap_remove(void *p) {
    for (size_t i = heap_objs.n; i-- > 0;)
        if (heap_objs.v[i].lo == (uintptr_t)p) {
            size_t n = heap_objs.v[i].hi - heap_objs.v[i].lo;
            heap_objs.v[i] = heap_objs.v[--heap_objs.n];
            return n;
        }
    return (size_t)-1;
}
static int sample_running(void);
static void mark_dirty(void);
#define ARENA_CAP ((size_t)4 << 30)
static char *arena_base, *arena_top; /* arena_top is restored with __DATA: the restore empties it */
static uintptr_t last_setup_lo;      /* the setup's most recent block (the driver's sample buffer) */
static size_t last_setup_n;

static void *arena_alloc(size_t n, size_t al) {
    if (!arena_base) return 0;
    uintptr_t a = ((uintptr_t)arena_top + al - 1) & ~(uintptr_t)(al - 1);
    if (a + (n ? n : 1) > (uintptr_t)arena_base + ARENA_CAP) return 0;
    arena_top = (char *)(a + (n ? n : 1));
    return (void *)a;
}

static int in_arena(const void *p) {
    return arena_base && (const char *)p >= arena_base && (const char *)p < arena_base + ARENA_CAP;
}

static void *heap_alloc(size_t al, size_t n) {
    void *p = 0;
    if (sample_running()) {
        p = arena_alloc(n, al < 16 ? 16 : al);
        if (!p) mark_dirty();
    }
    if (!p) {
        if (al <= 16) p = calloc(1, n ? n : 1);
        else if (posix_memalign(&p, al < sizeof(void *) ? sizeof(void *) : al, n ? n : 1)) p = 0;
        else memset(p, 0, n ? n : 1);
        if (p && !sample_running()) last_setup_lo = (uintptr_t)p, last_setup_n = n;
    }
    if (p) heap_add(p, n);
    return p;
}

void *__cqo_malloc(size_t n) { return heap_alloc(16, n); }
void *__cqo_calloc(size_t k, size_t n) {
    if (n && k > SIZE_MAX / n) return 0;
    return __cqo_malloc(k * n);
}
void *__cqo_valloc(size_t n) { return __cqo_malloc(n); }
void *__cqo_aligned_alloc(size_t al, size_t n) {
    if (al & (al - 1)) return 0;
    return heap_alloc(al, n);
}
int __cqo_posix_memalign(void **out, size_t al, size_t n) {
    void *p = __cqo_aligned_alloc(al, n);
    if (!p) return ENOMEM;
    *out = p;
    return 0;
}
/* A sample never frees a block: an arena block goes with the arena, a setup block is put back. */
static void heap_release(void *p) {
    if (!sample_running() && !in_arena(p)) free(p);
}
void __cqo_free(void *p) {
    if (!p) return;
    heap_remove(p);
    heap_release(p);
}
void *__cqo_realloc(void *p, size_t n) {
    if (!p) return __cqo_malloc(n);
    size_t old = heap_remove(p);
    void *q = __cqo_malloc(n);
    if (!q) { if (old != (size_t)-1) heap_add(p, old); return 0; }
    if (old == (size_t)-1) old = 0; /* not ours: nothing known to copy */
    memcpy(q, p, old < n ? old : n);
    heap_release(p);
    return q;
}
void *__cqo_reallocf(void *p, size_t n) {
    void *q = __cqo_realloc(p, n);
    if (!q && p) __cqo_free(p);
    return q;
}

/* A non-constrained fp operation runs in the default environment (owner ruling on cq-0r1i):
 * OracleInstr.cpp brackets it with these two. The operation's own flags vanish with the restore. */
static fenv_t fpdfl_saved;
void __cqo_fpdfl_enter(void) {
    fegetenv(&fpdfl_saved);
    fesetenv(FE_DFL_ENV);
}
void __cqo_fpdfl_leave(void) { fesetenv(&fpdfl_saved); }
/* fenv as rule 23 models it (cq-fvs2; references 81, 82, 100), not as the host libm does. The flags
 * are the five IEEE bits of x86-64 (INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32):
 * macOS also reports FE_DENORMAL (0x02, raised by an SSE op on a subnormal) and counts it in
 * FE_ALL_EXCEPT, so every flag read masks it out. feraiseexcept(m) is flags | m exactly (macOS raises
 * by arithmetic: OVERFLOW brings INEXACT); feupdateenv raises the saved flags the same way. A
 * fexcept_t holds the flag bits. fesetround(m) is valid iff (m & ~0xC00) == 0 and returns 0, else
 * returns 1 and leaves the mode. The mode and the environment calls otherwise run on the host FPU. */
#define CQO_FE_IEEE (FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW | FE_UNDERFLOW | FE_INEXACT)

static void fe_set_exactly(int m) { /* raise the flags in m, no arithmetic, no trap */
    m &= CQO_FE_IEEE;
    if (!m) return;
    fexcept_t f = (fexcept_t)m;
    fesetexceptflag(&f, m);
}
int __cqo_fetestexcept(int m) { return fetestexcept(m & CQO_FE_IEEE); }
int __cqo_feclearexcept(int m) { return feclearexcept(m & CQO_FE_IEEE) ? -1 : 0; }
int __cqo_feraiseexcept(int m) { fe_set_exactly(m); return 0; }
int __cqo_fegetexceptflag(fexcept_t *p, int m) { *p = (fexcept_t)fetestexcept(m & CQO_FE_IEEE); return 0; }
int __cqo_fesetexceptflag(const fexcept_t *p, int m) {
    m &= CQO_FE_IEEE;
    int saved = (int)*p & m;
    feclearexcept(m & ~saved);
    fe_set_exactly(saved);
    return 0;
}
int __cqo_fesetround(int m) {
    if (m & ~0xC00) return 1;
    return fesetround(m) ? 1 : 0;
}
int __cqo_feupdateenv(const fenv_t *e) {
    int cur = fetestexcept(CQO_FE_IEEE);
    if (fesetenv(e)) return -1;
    fe_set_exactly(cur);
    return 0;
}

/* threads: single-thread collapse (rule 24). pthread_create runs the routine to completion. */
static void *thread_results[1024];
static unsigned nthreads;
int __cqo_pthread_create(pthread_t *t, const pthread_attr_t *a, void *(*fn)(void *), void *arg) {
    (void)a;
    if (nthreads >= 1024) return EAGAIN;
    unsigned id = nthreads++;
    *t = (pthread_t)(uintptr_t)(id + 1);
    thread_results[id] = fn(arg);
    return 0;
}
int __cqo_pthread_join(pthread_t t, void **ret) {
    uintptr_t id = (uintptr_t)t;
    if (id == 0 || id > nthreads) return ESRCH;
    if (ret) *ret = thread_results[id - 1];
    return 0;
}
int __cqo_pthread_detach(pthread_t t) { (void)t; return 0; }

/* ------------------------------------------------------------------ CR §2 fp -> int */
static int64_t c32(double x) {
    if (x > -2147483649.0 && x < 2147483648.0) return (int32_t)x;
    feraiseexcept(FE_INVALID);
    return INT32_MIN;
}
static int64_t c64(double x) {
    if (x >= -9223372036854775808.0 && x < 9223372036854775808.0) return (int64_t)x;
    feraiseexcept(FE_INVALID);
    return INT64_MIN;
}
/* f16/f32 arrive widened to f64 exactly; c32/c64 of the widened value is the cvtt of the narrow one,
 * and x - 2^63 is exact or rounds to the same truncation in either width. */
int64_t __cqo_fpto64(double x, int32_t w, int32_t sgn) {
    if (sgn) return w == 64 ? c64(x) : c32(x);
    if (w <= 16) return c32(x);
    if (w == 32) return c64(x);
    int64_t r1 = c64(x), r2 = c64(x - 9223372036854775808.0);
    return r1 | (r2 & (r1 >> 63));
}
static int64_t fist(long double x, int b) {
    long double lim = b == 16 ? 32768.0L : b == 32 ? 2147483648.0L : 9223372036854775808.0L;
    if (x > -lim - 1.0L && x < lim) return (int64_t)x;
    feraiseexcept(FE_INVALID);
    return b == 16 ? INT16_MIN : b == 32 ? INT32_MIN : INT64_MIN;
}
int64_t __cqo_fpto80(long double x, int32_t w, int32_t sgn) {
    if (sgn) return w <= 16 ? fist(x, 16) : fist(x, w);
    if (w <= 16) return fist(x, 32);
    if (w == 32) return fist(x, 64);
    if (x < 9223372036854775808.0L) return fist(x, 64);
    return (int64_t)((uint64_t)fist(x - 9223372036854775808.0L, 64) ^ 0x8000000000000000ULL);
}

/* ------------------------------------------------------------------ events */
/* cq_theta substitution (cq-6m2, cq-arch Z4): this sample's chosen values, per site and reach */
#define MAXSUBST 8192
#define MAXSKEY 512
static struct sub { int key, occ; uint64_t w[2]; } *subst;  /* MAXSUBST, off __DATA */
static int nsubst;
static struct skey { char fn[256]; int site, period; long reach; } *skeys; /* MAXSKEY */
static int nskeys;

static int skey_of(const char *fn, int site) {
    for (int i = 0; i < nskeys; ++i)
        if (skeys[i].site == site && !strcmp(skeys[i].fn, fn)) return i;
    return -1;
}

/* entries of RunResult side 'c' rotations / measured so far (T2 cut, mcut) */
static long n_rotations, n_measured;

static const char *kinds[] = {"theta", "phi", "measure", "invert_begin", "invert_end"};

void __cqo_site(const char *fn, int32_t site, int32_t kind, uint64_t angle, void *reg, int32_t bits) {
    int sk = kind == 0 ? skey_of(fn, site) : -1;
    if (sk >= 0) {
        int occ = (int)(skeys[sk].reach++ % skeys[sk].period);
        for (int i = 0; i < nsubst; ++i)
            if (subst[i].key == sk && subst[i].occ == occ) {
                unsigned nb = ((unsigned)bits + 7) / 8;
                memset(reg, 0, nb);
                memcpy(reg, subst[i].w, nb > 16 ? 16 : nb);
                if (bits % 8) ((unsigned char *)reg)[nb - 1] &= (unsigned char)((1u << (bits % 8)) - 1);
                break;
            }
    }
    char f[300], a[40] = "null", r[64] = "null", line[600];
    jsonstr(f, sizeof f, fn);
    if (kind == 0 || kind == 1) {
        char h[40];
        hexbits(h, (const unsigned char *)&angle, 64);
        snprintf(a, sizeof a, "\"%s\"", h);
    }
    if (reg) {
        char h[48];
        hexbits(h, reg, (unsigned)bits);
        snprintf(r, sizeof r, "\"%s\"", h);
    }
    snprintf(line, sizeof line, "{\"ev\":\"site\",\"fn\":%s,\"site\":%d,\"kind\":\"%s\",\"angle\":%s,\"reg\":%s}",
             f, site, kinds[kind], a, r);
    out_line(trace_fd, line);
    if (kind == 2) n_measured++;
    else n_rotations++;
}

/* ------------------------------------------------------------------ the cutoff K (CR §6, cq-8ay)
 * OracleInstr.cpp passes kq = 1 where the loop is a quantum-exit loop in the running specialization.
 * Each activation of one gets a T2 record when it ends: by an exit edge (capped false), or when the
 * trip counter reaches K+1 trips begun (capped true, n = K, cut/mcut = entries so far); the capped
 * one ends the sample. A quantum-depth recursion is counted by the level calls along the chain. */
int32_t __cqo_spec_next; /* the callee's specialization id; -1: the driver's call (its entry spec) */

#define MAXACT 256
static struct { const char *id; long n; } acts[MAXACT];
static int nacts;

static long next_act(const char *id) {
    for (int i = 0; i < nacts; ++i)
        if (!strcmp(acts[i].id, id)) return acts[i].n++;
    if (nacts == MAXACT) { note("internal more than %d cutoff loops", MAXACT); _exit(95); }
    acts[nacts].id = id, acts[nacts].n = 1;
    nacts++;
    return 0;
}

static void kloop_record(const char *id, long long n, int capped) {
    char l[300], line[600];
    jsonstr(l, sizeof l, id);
    long act = next_act(id);
    if (capped)
        snprintf(line, sizeof line,
                 "{\"ev\":\"kloop\",\"loop\":%s,\"act\":%ld,\"n\":%lld,\"capped\":true,\"cut\":%ld,\"mcut\":%ld}",
                 l, act, n, n_rotations, n_measured);
    else
        snprintf(line, sizeof line, "{\"ev\":\"kloop\",\"loop\":%s,\"act\":%ld,\"n\":%lld,\"capped\":false}",
                 l, act, n);
    out_line(trace_fd, line);
}

static void kcap(const char *id, long long K) {
    kloop_record(id, K, 1);
    note("cap %s", id);
    _exit(0);
}

void __cqo_trip(const char *loop, int64_t n, int32_t kq) {
    char l[300], line[400];
    jsonstr(l, sizeof l, loop);
    snprintf(line, sizeof line, "{\"ev\":\"trip\",\"loop\":%s,\"n\":%lld}", l, (long long)n);
    out_line(trace_fd, line);
    if (kq) kloop_record(loop, n, 0);
}

/* cnt trips begun (the counter after this header run, or before entering the body of a loop that
 * tests at its header): one more than K means the exit test after the K-th body admitted trip K+1. */
void __cqo_kcheck(const char *loop, int64_t cnt, int64_t K, int32_t kq) {
    if (kq && cnt > K) kcap(loop, K);
}

#define MAXREC 64
static struct { const char *id; long long K, depth, max; } recs[MAXREC];
static int nrecs;

void __cqo_rec_enter(const char *id, int64_t K, int32_t on) {
    if (!on) return;
    if (nrecs == MAXREC) { note("internal recursion activations nested deeper than %d", MAXREC); _exit(95); }
    recs[nrecs].id = id, recs[nrecs].K = K, recs[nrecs].depth = 0, recs[nrecs].max = 0;
    nrecs++;
}

void __cqo_rec_exit(int32_t on) {
    if (!on) return;
    if (nrecs == 0) { note("internal recursion exit outside an activation"); _exit(95); }
    nrecs--;
    kloop_record(recs[nrecs].id, recs[nrecs].max, 0);
}

void __cqo_rec_down(int32_t on) {
    if (!on) return;
    if (nrecs == 0) { note("internal recursion level outside an activation"); _exit(95); }
    long long d = ++recs[nrecs - 1].depth;
    if (d > recs[nrecs - 1].K) kcap(recs[nrecs - 1].id, recs[nrecs - 1].K);
    if (d > recs[nrecs - 1].max) recs[nrecs - 1].max = d;
}

void __cqo_rec_up(int32_t on) {
    if (on && nrecs) recs[nrecs - 1].depth--;
}

static uint64_t ticks, tripcap = 10000000;
void __cqo_tick(void) {
    if (++ticks > tripcap) { note("tripcap"); _exit(98); }
}

void __cqo_ret(const void *p, int32_t bits) {
    char line[160];
    if (!p) {
        snprintf(line, sizeof line, "{\"ev\":\"ret\",\"v\":null}");
    } else {
        char h[48];
        hexbits(h, p, (unsigned)bits);
        snprintf(line, sizeof line, "{\"ev\":\"ret\",\"v\":\"%s\"}", h);
    }
    out_line(trace_fd, line);
}

void __cqo_noreturn(const char *callee) { note("noreturn %s", callee); }
void __cqo_raise_note(int32_t sig) { note("raise %d", sig); }
void __cqo_unreachable(const char *fn) { note("ub unreachable %s", fn); _exit(97); }

/* The checker's stand-in for a function nothing defines: one source with the evaluator (cq-rft). */
uint64_t __cqo_mix(uint64_t h, uint64_t w) { return cq_standin_mix(h, w); }

/* A driver setup that allocates rails (`cqrt_alloc_<W>(v)`) means the value v on the C side. */
int32_t cqrt_alloc_i1(_Bool v) { return v; }
int32_t cqrt_alloc_i8(int8_t v) { return v; }
int32_t cqrt_alloc_i16(int16_t v) { return v; }
int32_t cqrt_alloc_i32(int32_t v) { return v; }

/* ------------------------------------------------------------------ samples (cq-pz9h)
 *
 * The driver (oracle.py) brackets each record's call with
 *   before_call  if (sigsetjmp(*__cqo_jb(), 1) != 0) __cqo_resume(); else if (__cqo_sample_begin(CQD_SAMPLE)) {
 *   after_call   __cqo_sample_end(); }
 * The batch process runs the setup once. At its first record it becomes the server: it forks one
 * worker and from then on only waits and skips records. The worker runs the records in-process, one
 * after another, and between two puts back everything a sample can change, so that each sample starts
 * from the state a child forked for it alone would have had (the server's post-setup state):
 *   - the executable's writable data (__DATA): the program's globals and this runtime's statics (the
 *     object tables' counts, the cutoff and recursion records, the trip ticks, the theta reaches);
 *   - the heap: what a sample allocates lies in the sample arena, emptied (and zeroed) after it; a
 *     setup block a sample frees or reallocates is not freed, and every setup block's bytes are put
 *     back (except the driver's sample buffer, which only the driver reads); the heap table's entries;
 *   - the stack from the driver's frame up (the setup's locals), the fp environment, errno.
 * A sample ends as the forked child did, and gets the same notes: by return ("wait exited 0"), by
 * exit/_exit/_Exit(n) or one of this runtime's own ends ("wait exited n"), by abort with SIGABRT at its
 * default ("wait signaled 6"); in-process, with a jump back to the driver. A crash, a timeout
 * (SIGALRM) or any other signal ends the worker after its notes; the server writes the "wait" note of a
 * worker that died inside a sample and forks a fresh worker for the next record, so that sample's end
 * is exactly the fork-per-sample one. Isolated modules (oracle.py: process state the restore does not
 * cover, such as signal handlers, atexit or rand) run every sample in a worker of its own, and their
 * exit and abort are the C library's. A sample whose allocation passes the arena also ends its worker.
 *
 *   prog <trace> <status> <timeout_ms> <tripcap> [<subst>]          one batch ($CQD_SAMPLES)
 *   prog --serve                                                     a batch per stdin line:
 *       <trace> <status> <err> <timeout_ms> <tripcap> <isolate 0|1> <samples> <subst|->
 *     each batch runs in a child forked from the pristine process; the reply is one line, the batch's
 *     exit status (0 when it ran). */
#include <dlfcn.h>
#include <mach-o/getsect.h>
#include <mach-o/ldsyms.h>
#include <setjmp.h>

static long timeout_ms = 2000;
static int isolate;

/* the batch's substitutions, parsed once: per sample, its lines (system heap, never put back) */
typedef struct { long idx; char fn[256]; int site, period, occ, k; uint64_t w[2]; } subline;
static subline *sublines;
static size_t nsublines;

static void load_subst_file(const char *path) {
    nsublines = 0;
    if (!path) return;
    FILE *f = fopen(path, "r");
    if (!f) return;
    size_t cap = 0;
    char line[1024];
    while (fgets(line, sizeof line, f)) {
        char *save = 0, *tok = strtok_r(line, " \t\r\n", &save);
        if (!tok) continue;
        if (nsublines == cap) {
            cap = cap ? 2 * cap : 256;
            sublines = realloc(sublines, cap * sizeof *sublines);
            if (!sublines) { fprintf(stderr, "cqo: out of memory\n"); _exit(2); }
        }
        subline *l = &sublines[nsublines];
        memset(l, 0, sizeof *l);
        l->idx = strtol(tok, 0, 10);
        char *fn = strtok_r(0, " \t\r\n", &save), *st = strtok_r(0, " \t\r\n", &save),
             *pe = strtok_r(0, " \t\r\n", &save), *oc = strtok_r(0, " \t\r\n", &save),
             *n = strtok_r(0, " \t\r\n", &save);
        if (!fn || !st || !pe || !oc || !n || strlen(fn) >= sizeof l->fn) l->period = -1; /* malformed */
        else {
            snprintf(l->fn, sizeof l->fn, "%s", fn);
            l->site = (int)strtol(st, 0, 10), l->period = (int)strtol(pe, 0, 10);
            l->occ = (int)strtol(oc, 0, 10);
            l->k = (int)strtol(n, 0, 10);
            for (int i = 0; i < l->k && i < 2; ++i) {
                char *x = strtok_r(0, " \t\r\n", &save);
                if (x) l->w[i] = strtoull(x, 0, 16);
            }
        }
        nsublines++;
    }
    fclose(f);
}

/* this sample's cq_theta substitutions */
static void load_subst(long idx) {
    nsubst = nskeys = 0;
    for (size_t j = 0; j < nsublines; ++j) {
        subline *l = &sublines[j];
        if (l->idx != idx) continue;
        if (l->period < 1) { note("internal malformed subst line"); _exit(95); }
        int sk = skey_of(l->fn, l->site);
        if (sk < 0) {
            if (nskeys == MAXSKEY) { note("internal more than %d substituted sites", MAXSKEY); _exit(95); }
            sk = nskeys++;
            snprintf(skeys[sk].fn, sizeof skeys[sk].fn, "%s", l->fn);
            skeys[sk].site = l->site, skeys[sk].period = l->period, skeys[sk].reach = 0;
        }
        if (nsubst == MAXSUBST) { note("internal more than %d substituted reaches", MAXSUBST); _exit(95); }
        subst[nsubst].key = sk;
        subst[nsubst].occ = l->occ;
        subst[nsubst].w[0] = l->w[0], subst[nsubst].w[1] = l->w[1];
        nsubst++;
    }
}

/* -- exits -- */
typedef void (*exit_fn_t)(int) __attribute__((noreturn));
typedef void (*abort_fn_t)(void) __attribute__((noreturn));
static exit_fn_t real_exit, real__exit;
static abort_fn_t real_abort;

__attribute__((constructor(101))) static void cqo_ctor(void) {
    real_exit = (exit_fn_t)dlsym(RTLD_NEXT, "exit");
    real__exit = (exit_fn_t)dlsym(RTLD_NEXT, "_exit");
    real_abort = (abort_fn_t)dlsym(RTLD_NEXT, "abort");
    if (!real_exit || !real__exit || !real_abort) { fprintf(stderr, "cqo: no exit/_exit/abort\n"); raise(SIGKILL); }
    subst = mmap(0, MAXSUBST * sizeof *subst, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    skeys = mmap(0, MAXSKEY * sizeof *skeys, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (subst == MAP_FAILED || skeys == MAP_FAILED) { fprintf(stderr, "cqo: mmap\n"); raise(SIGKILL); }
}

/* -- the shared state -- */
struct shot {
    sigjmp_buf jb;
    pid_t server, worker;
    long resume, next, cur;
    volatile long progress;
    volatile int in_sample, dirty;
    int snapped, err;
    struct { char *at, *copy; size_t n; } sect[6];
    int nsect;
    obj *heap_tab;            /* heap_objs entries at the snapshot */
    size_t heap_n;
    char **heap_copy;         /* their bytes (null: not put back) */
    fenv_t fenv;
    char *stack_lo, *stack_copy;
    size_t stack_n, stack_cap;
    obuf tr, st;
};
static struct shot *R;
static int is_worker; /* set before the snapshot: stays set */

static int sample_running(void) { return is_worker && R->in_sample; }
static void mark_dirty(void) { if (R) R->dirty = 1; }

static void die(const char *what) {
    fprintf(stderr, "cqo: %s: %s\n", what, strerror(errno));
    real__exit(2);
}

static void *sys_alloc(size_t n) {
    void *p = malloc(n ? n : 1);
    if (!p) die("out of memory");
    return p;
}

static void timer_ms(long ms, int periodic) {
    struct itimerval it;
    memset(&it, 0, sizeof it);
    if (ms > 0) {
        it.it_value.tv_sec = ms / 1000, it.it_value.tv_usec = (ms % 1000) * 1000;
        if (periodic) it.it_interval = it.it_value;
    }
    setitimer(ITIMER_REAL, &it, 0);
}

/* the worker leaves (a crash, a timeout, a dirty or isolated sample): its output, then the end */
static void worker_leave(void) {
    ob_flush(ob_trace, trace_fd);
    ob_flush(ob_status, status_fd);
    real__exit(0);
}

/* A sample's in-process end: the driver's sigsetjmp returns again (__cqo_resume). */
__attribute__((noreturn)) static void sample_jump(void) { siglongjmp(R->jb, 1); }

void exit(int code) {
    if (sample_running() && !isolate) { note("wait exited %d", code & 0xff); sample_jump(); }
    real_exit(code);
}
void _exit(int code) {
    if (sample_running() && !isolate) { note("wait exited %d", code & 0xff); sample_jump(); }
    real__exit(code);
}
void _Exit(int code) { _exit(code); }
void abort(void) {
    if (sample_running() && !isolate) {
        struct sigaction cur;
        if (sigaction(SIGABRT, 0, &cur) == 0 && !(cur.sa_flags & SA_SIGINFO) && cur.sa_handler == SIG_DFL) {
            note("wait signaled %d", SIGABRT);
            sample_jump();
        }
    }
    real_abort();
}

static void on_crash(int sig, siginfo_t *si, void *uc) {
    (void)uc;
    note("crash %s addr=%p", sig == SIGSEGV ? "SIGSEGV" : sig == SIGBUS ? "SIGBUS" : "SIGFPE", si->si_addr);
    if (!sample_running()) real__exit(94);
    note("wait exited 94");
    R->next = R->cur + 1;
    R->in_sample = 0;
    worker_leave();
}

static void on_timeout(int sig) {
    (void)sig;
    if (!sample_running()) { signal(SIGALRM, SIG_DFL); raise(SIGALRM); return; }
    note("wait timeout");
    R->next = R->cur + 1;
    R->in_sample = 0;
    worker_leave();
}

/* -- the snapshot -- */
static void snapshot_take(void) {
    static const char *segs[] = {"__DATA", "__DATA_DIRTY"};
    static const char *names[] = {"__data", "__bss", "__common"};
    R->nsect = 0;
    for (int s = 0; s < 2; ++s)
        for (int i = 0; i < 3; ++i) {
            unsigned long n = 0;
            uint8_t *at = getsectiondata(&_mh_execute_header, segs[s], names[i], &n);
            if (!at || !n) continue;
            R->sect[R->nsect].at = (char *)at;
            R->sect[R->nsect].n = n;
            R->sect[R->nsect].copy = sys_alloc(n);
            R->nsect++;
        }
    /* the setup's heap blocks; the last one is the driver's sample buffer when it has its size */
    size_t buf_n = (size_t)-1;
    const char *sp = getenv("CQD_SAMPLES");
    struct stat st;
    if (sp && stat(sp, &st) == 0) buf_n = (size_t)st.st_size + 1;
    R->heap_n = heap_objs.n;
    R->heap_tab = sys_alloc(R->heap_n * sizeof(obj));
    R->heap_copy = sys_alloc(R->heap_n * sizeof(char *));
    for (size_t i = 0; i < R->heap_n; ++i) {
        obj o = heap_objs.v[i];
        R->heap_tab[i] = o;
        size_t n = o.hi - o.lo;
        if (o.lo == last_setup_lo && n == last_setup_n && n == buf_n) { R->heap_copy[i] = 0; continue; }
        R->heap_copy[i] = sys_alloc(n);
        memcpy(R->heap_copy[i], (void *)o.lo, n);
    }
    fegetenv(&R->fenv);
    R->err = errno;
    R->snapped = 1;
    for (int i = 0; i < R->nsect; ++i) memcpy(R->sect[i].copy, R->sect[i].at, R->sect[i].n);
}

static void snapshot_restore(void) {
    if (arena_base && arena_top > arena_base) memset(arena_base, 0, (size_t)(arena_top - arena_base));
    for (int i = 0; i < R->nsect; ++i) memcpy(R->sect[i].at, R->sect[i].copy, R->sect[i].n);
    memcpy(heap_objs.v, R->heap_tab, R->heap_n * sizeof(obj));
    for (size_t i = 0; i < R->heap_n; ++i)
        if (R->heap_copy[i]) memcpy((void *)R->heap_tab[i].lo, R->heap_copy[i], R->heap_tab[i].hi - R->heap_tab[i].lo);
    fesetenv(&R->fenv);
    errno = R->err;
}

static void stack_save(char *lo) {
    char *hi = (char *)pthread_get_stackaddr_np(pthread_self());
    if (!(lo < hi)) die("stack bounds");
    R->stack_lo = lo;
    R->stack_n = (size_t)(hi - lo);
    if (R->stack_n > R->stack_cap) {
        R->stack_copy = sys_alloc(R->stack_n);
        R->stack_cap = R->stack_n;
    }
    memcpy(R->stack_copy, lo, R->stack_n);
}

__attribute__((noinline)) static void stack_restore(void) {
    char *here = (char *)__builtin_frame_address(0);
    if (here + 64 > R->stack_lo) { fprintf(stderr, "cqo: the driver's frame moved during a sample\n"); real__exit(2); }
    memcpy(R->stack_lo, R->stack_copy, R->stack_n);
}

/* -- the server -- */
static volatile sig_atomic_t server_tick;
static void server_on_alarm(int sig) { (void)sig; server_tick = 1; }

static void server_setup(void) {
    void *m = mmap(0, sizeof(struct shot), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
    if (m == MAP_FAILED) die("mmap");
    R = m;
    memset(R, 0, sizeof *R);
    R->server = getpid();
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = server_on_alarm; /* no SA_RESTART: waitpid returns EINTR */
    sigemptyset(&sa.sa_mask);
    sigaction(SIGALRM, &sa, 0);
}

static void server_wait(void) {
    long last = -1;
    int killed = 0, st = 0;
    server_tick = 0;
    timer_ms(2 * timeout_ms + 200, 1);
    for (;;) {
        pid_t r = waitpid(R->worker, &st, 0);
        if (r == R->worker) break;
        if (r < 0 && errno == EINTR) {
            if (server_tick) {
                server_tick = 0;
                if (R->progress == last && !killed) kill(R->worker, SIGKILL), killed = 1;
                last = R->progress;
            }
            continue;
        }
        die("waitpid");
    }
    timer_ms(0, 0);
    ob_flush(&R->tr, trace_fd); /* what the worker left unwritten (whole lines) */
    ob_flush(&R->st, status_fd);
    if (!R->in_sample) { R->resume = R->next; return; }
    cur_sample = R->cur;
    if (killed || (WIFSIGNALED(st) && WTERMSIG(st) == SIGALRM)) note("wait timeout");
    else if (WIFSIGNALED(st)) note("wait signaled %d", WTERMSIG(st));
    else if (WIFEXITED(st)) note("wait exited %d", WEXITSTATUS(st));
    else note("wait unknown %d", st);
    cur_sample = -1;
    R->in_sample = 0;
    R->resume = R->cur + 1;
}

static void worker_start(void) {
    is_worker = 1;
    R->worker = getpid();
    R->snapped = 0, R->dirty = 0, R->in_sample = 0;
    R->tr.n = R->st.n = 0;
    R->stack_copy = 0, R->stack_cap = 0; /* the last worker's copies were its own */
    ob_trace = &R->tr, ob_status = &R->st;
    timer_ms(0, 0);
    int devnull = open("/dev/null", O_WRONLY);
    if (devnull >= 0) dup2(devnull, 1), dup2(devnull, 2), close(devnull);
    stack_t ss = {.ss_sp = sys_alloc(1 << 16), .ss_size = 1 << 16, .ss_flags = 0};
    sigaltstack(&ss, 0);
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_sigaction = on_crash;
    sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigaction(SIGSEGV, &sa, 0);
    sigaction(SIGBUS, &sa, 0);
    sigaction(SIGFPE, &sa, 0);
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = on_timeout;
    sa.sa_flags = SA_ONSTACK;
    sigaction(SIGALRM, &sa, 0);
    if (!arena_base) {
        void *a = mmap(0, ARENA_CAP, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
        if (a == MAP_FAILED) die("mmap");
        arena_base = arena_top = a;
    }
}

/* -- the driver's hooks -- */
sigjmp_buf *__cqo_jb(void) {
    if (!R) server_setup();
    return &R->jb;
}

/* before_call: 1 in the worker (run the sample), 0 in the server (skip the record). */
int __cqo_sample_begin(int idx) {
    if (!R) server_setup();
    if (!is_worker) {
        if (idx < R->resume) return 0;
        R->next = idx;
        fflush(0);
        pid_t pid = fork();
        if (pid < 0) die("fork");
        if (pid > 0) {
            R->worker = pid;
            server_wait();
            return 0;
        }
        worker_start();
    }
    if (!R->snapped) snapshot_take();
    cur_sample = idx;
    R->cur = idx;
    load_subst(idx);
    __cqo_spec_next = -1; /* the driver's call enters its callee's entry specialization */
    stack_save((char *)__builtin_frame_address(0) + 16);
    R->progress++;
    R->in_sample = 1;
    timer_ms(timeout_ms, 0);
    return 1;
}

static void sample_finish(void) {
    timer_ms(0, 0);
    R->next = R->cur + 1; /* before in_sample drops: the server never runs a finished sample again */
    R->in_sample = 0;
    R->progress++;
    if (R->dirty || isolate) worker_leave();
    stack_restore();
    snapshot_restore();
}

/* after_call: the call returned. An activation the driver's call entered (a recursive entry
 * function) ended with the call. */
void __cqo_sample_end(void) {
    while (nrecs) __cqo_rec_exit(1);
    note("wait exited 0");
    sample_finish();
}

/* the driver's sigsetjmp returned again: the sample ended by exit, _exit, abort or this runtime */
void __cqo_resume(void) { sample_finish(); }

int __cqo_drv_main(void); /* drivers.driver_source(..., main_name="__cqo_drv_main") */

/* One batch in this process; its exit status. */
static int run_batch(const char *trace, const char *status, const char *subst_path) {
    trace_fd = open(trace, O_WRONLY | O_CREAT | O_APPEND | O_TRUNC, 0644);
    status_fd = open(status, O_WRONLY | O_CREAT | O_APPEND | O_TRUNC, 0644);
    if (trace_fd < 0 || status_fd < 0) { perror("cqo"); return 2; }
    load_subst_file(subst_path);
    __cqo_drv_main();
    if (is_worker) worker_leave(); /* the worker ran the last record */
    return 0;
}

static int serve(void) {
    char line[8192];
    setvbuf(stdout, 0, _IOLBF, 0);
    while (fgets(line, sizeof line, stdin)) {
        char tr[2048], stp[2048], err[2048], smp[2048], sub[2048];
        long to;
        unsigned long long cap;
        int iso;
        if (sscanf(line, "%2047s %2047s %2047s %ld %llu %d %2047s %2047s", tr, stp, err, &to, &cap, &iso, smp, sub) != 8) {
            printf("bad\n");
            continue;
        }
        fflush(0);
        pid_t pid = fork();
        if (pid < 0) die("fork");
        if (pid == 0) {
            int in = open("/dev/null", O_RDONLY), out = open("/dev/null", O_WRONLY),
                e = open(err, O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (in >= 0) dup2(in, 0);
            if (out >= 0) dup2(out, 1);
            if (e >= 0) dup2(e, 2);
            timeout_ms = to, tripcap = cap, isolate = iso;
            setenv("CQD_SAMPLES", smp, 1);
            real__exit(run_batch(tr, stp, strcmp(sub, "-") ? sub : 0));
        }
        int st = 0;
        while (waitpid(pid, &st, 0) < 0)
            if (errno != EINTR) die("waitpid");
        printf("%d\n", WIFEXITED(st) ? WEXITSTATUS(st) : 128 + (WIFSIGNALED(st) ? WTERMSIG(st) : 0));
    }
    return 0;
}

int main(int argc, char **argv) {
    if (argc == 2 && !strcmp(argv[1], "--serve")) return serve();
    if (argc != 5 && argc != 6 && argc != 7) {
        fprintf(stderr, "usage: %s trace status timeout_ms tripcap [subst [isolate]] | --serve\n", argv[0]);
        return 2;
    }
    timeout_ms = strtol(argv[3], 0, 10);
    tripcap = strtoull(argv[4], 0, 10);
    if (argc == 7) isolate = atoi(argv[6]);
    int r = run_batch(argv[1], argv[2], argc >= 6 && strcmp(argv[5], "-") ? argv[5] : 0);
    fflush(0);
    real__exit(r);
}
