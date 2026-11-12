/* cqo_rt.c: runtime of the C oracle (cq-w0-chk-oracle). Linked with the program instrumented by
 * OracleInstr.cpp and a driver from drivers.driver_source(spec, samples, main_name="__cqo_drv_main",
 * before_call/after_call as oracle.py BEFORE_CALL/AFTER_CALL, see "samples" below).
 * C17, compiled separately, never instrumented.
 *
 *   prog <trace> <status> <timeout_ms> <tripcap> [<subst> [<isolate>]]   or   prog --serve
 *
 * The driver's setup runs once; each sample's call runs from that state as a child forked for it
 * alone would (in-process, see "samples" below), so a trap, an abort or a hang ends that sample only.
 * The sample appends `<index>\t<event JSON>` lines to
 * <trace> and `<index>\t<note>` lines to <status>; the parent adds `<index>\twait exited N|signaled
 * S`, or `hang wall` when it killed a worker that made no progress. Notes: `noreturn <callee>`, `raise <sig>`, `ub unreachable <fn>`, `ub oob-atomic`,
 * `tripcap`, `crash <signal> addr=<a>`, `oob-load`, `oob-store`, `cap <loop>` (a quantum-exit loop or
 * quantum-depth recursion stopped after K trips: the sample ends there, not a failure; cq-8ay),
 * `internal <why>`, `hang cpu <ms>`.
 * Determinism (cq-sqn6): no sample outcome depends on time or machine load. Nontermination is the
 * tripcap step budget (loop-header executions). <timeout_ms> is only a hang guard, in the worker's CPU
 * time (ITIMER_PROF, so a loaded machine does not reach it sooner), with a wall-clock backstop in the
 * server for a worker that makes no progress at all (HANG_WALL_MS); either reports `hang ...`, which
 * oracle.py raises as an internal error of the checker, never a sample verdict.
 * The cutoff records of cq-arch T2 go to <trace> as `{"ev":"kloop","loop","act","n","capped"[,"cut",
 * "mcut"]}` lines (oracle.py moves them to outputs["loops"]; they are not trace events).
 * <subst> lines `<index> <fn> <site> <period> <occ> <nwords> <hex w>...` replace the register value at a
 * cq_theta site (cq-6m2, cq-arch Z4): the r-th reach (0-based) of site <fn>:<site> in sample <index>
 * takes the line whose <occ> is r mod <period>; a site with no line keeps its value (the identity).
 * Host output (cq-e4jk): the program's stdout is a file of the batch (fd 1, unbuffered, so a sample
 * that ends by abort or a signal keeps what it printed); each sample's end writes it to <trace> as
 * `{"ev":"stdout","s"}` (the driver's setup output, then the sample's; bytes as code points) and cuts
 * the file back to the setup's part. Each call of a host-effect function (OracleInstr.cpp, effects)
 * writes `{"ev":"effect","name","args":[{"s"}|{"w","v"}]}` before it runs (oracle.py moves both to
 * SampleRun.stdout/effects; they are not trace events).
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
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../rt/cq_standin.h"
#include "../rt/libm_next.h"


/* ------------------------------------------------------------------ output */
static int trace_fd = -1, status_fd = -1;
static long cur_sample = -1;
/* Trip mode (cq-g8md; the serve request's ninth field): the run is only for the trip counters and the
 * outcome. No site event is written and no rule 2 shadow is kept (they decide only the site kinds, never
 * a value or a branch, so the outcome and every trip count are the full run's); each (loop, n) trip
 * event and non-capped cutoff record is written once, the trip event with "h", the header executions
 * so far (the cost of reaching that count); the sample's end writes {"ev":"ticks","n"}, all its header
 * executions. The sampler's runs past millions of header executions stay small (cq-g8md). */
static int trips_only;

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

static int trace_room(size_t n); /* the disk cap (cq-3fjt), below */

static void ob_flush(obuf *o, int fd) {
    size_t n = o->n;
    if (n && fd == trace_fd) trace_room(n);
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
static void sh_clear(const void *p, uint64_t n);          /* rule 2 shadow cells (cq-y1ll), below */
static void sh_move(void *d, const void *s, uint64_t n);
static uint32_t sh_get(uintptr_t a);
static void sh_put(uintptr_t a, uint32_t n);

void __cqo_global(void *p, uint64_t n) { ov_push(&global_objs, (uintptr_t)p, (uintptr_t)p + n); }
uint64_t __cqo_mark(void) { return stack_objs.n; }
void __cqo_release(uint64_t m) { if (m < stack_objs.n) stack_objs.n = m; }

/* llvm.stacksave / llvm.stackrestore (cq-t3kb): a restore deallocates every alloca made since its
 * save (LLVM LangRef), so it ends their objects as a return ends a frame's. Without it a VLA in a loop
 * (109's vla_loop_q) left one object per trip in the table, and every access to an older object
 * scanned them all: quadratic in the trips, past the hang guard well inside the cost budget. Each
 * save records the stack table's count; a restore releases to the count of the latest save of that
 * stack pointer still inside a live frame (count at most the table's), and drops the saves after it. */
typedef struct { uintptr_t sp; size_t mark; } ssave;
static ssave *ssv;
static size_t ssv_n;
#define SSV_CAP ((size_t)1 << 20) /* saves live at once (address space only) */
void __cqo_stacksave(void *p) {
    if (!ssv) {
        void *m = mmap(0, SSV_CAP * sizeof(ssave), PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
        if (m == MAP_FAILED) { fprintf(stderr, "cqo: mmap\n"); _exit(2); }
        ssv = m;
    }
    /* saves of frames that have returned (their count is past the table's) are dead */
    while (ssv_n && ssv[ssv_n - 1].mark > stack_objs.n) ssv_n--;
    if (ssv_n == SSV_CAP) { note("internal more than %zu live stack saves", SSV_CAP); _exit(95); }
    ssv[ssv_n].sp = (uintptr_t)p, ssv[ssv_n].mark = stack_objs.n, ssv_n++;
}
void __cqo_stackrestore(void *p) {
    for (size_t i = ssv_n; i-- > 0;)
        if (ssv[i].sp == (uintptr_t)p && ssv[i].mark <= stack_objs.n) {
            stack_objs.n = ssv[i].mark;
            ssv_n = i + 1;
            return;
        }
    note("internal a stackrestore without its stacksave");
    _exit(95);
}
void __cqo_alloca(void *p, uint64_t n) {
    /* cq-oou2: an alloca larger than the whole stack overflows it (a fault: outside the domain), but
     * its address lies in some other mapping (117's bool c[t] with t near 2^31 landed in the sample
     * arena), so zeroing it below would write gigabytes there: the fault the program takes */
    if (n > (uint64_t)pthread_get_stacksize_np(pthread_self())) {
        note("stack overflow: an alloca of %llu bytes", (unsigned long long)n);
        raise(SIGSEGV);
    }
    ov_push(&stack_objs, (uintptr_t)p, (uintptr_t)p + n);
    memset(p, 0, n); /* an uninitialized local reads 0 */
    sh_clear(p, n);
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

/* llvm.lifetime.start: nothing (CR §6, rulings Q16): a block-scoped object re-entered by a loop holds
 * what the trip before left there, rule 20's one block; a fresh object reads 0 by its allocation. */
void __cqo_zero(void *p, int64_t n) { (void)p, (void)n; }

/* The object an access belongs to: the one containing its base pointer, else the one containing the
 * accessed address. NULL: no object (every byte reads 0, stores are dropped). A base pointer one past
 * the end of an object A equals the lowest address of the object B placed after it, so an address
 * names both; LLVM's pointer is based on A (the access `gep inbounds A+size, -1` is inside A), so
 * when the access does not fit B and does fit the object ending at the base, that object is it
 * (cq-1jvr6 row 2: musl's stdin buffer read pointer after __toread). */
static int inside(const obj *o, uintptr_t a, uint64_t n);
static const obj *access_obj(const void *base, const void *p, uint64_t n) {
    const obj *o = base ? find_obj((uintptr_t)base) : 0;
    if (base && !inside(o, (uintptr_t)p, n) && (uintptr_t)base > 0) {
        const obj *e = find_obj((uintptr_t)base - 1);
        if (e && e->hi == (uintptr_t)base && inside(e, (uintptr_t)p, n)) return e;
    }
    return o ? o : find_obj((uintptr_t)p);
}

static int inside(const obj *o, uintptr_t a, uint64_t n) {
    return o && a >= o->lo && a + n <= o->hi && a + n >= a;
}

void __cqo_load(const void *p, uint64_t n, void *dst, const void *base) {
    const obj *o = access_obj(base, p, n);
    uintptr_t a = (uintptr_t)p;
    if (inside(o, a, n)) { memcpy(dst, p, n); return; }
    unsigned char *d = dst;
    for (uint64_t i = 0; i < n; ++i) d[i] = inside(o, a + i, 1) ? ((const unsigned char *)p)[i] : 0;
    if (oob_loads++ < 8) note("oob-load");
}

void __cqo_store(void *p, uint64_t n, const void *src, const void *base) {
    const obj *o = access_obj(base, p, n);
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
    sh_clear(p, n); /* the value's node, when quantum, is set after the call (OracleInstr.cpp shadows) */
    const obj *o = access_obj(base, p, n);
    uintptr_t a = (uintptr_t)p;
    if (inside(o, a, n)) { memset(p, v, n); return; }
    for (uint64_t i = 0; i < n; ++i)
        if (inside(o, a + i, 1)) ((unsigned char *)p)[i] = v;
    if (oob_stores++ < 8) note("oob-store");
}

void __cqo_imemmove(void *d, const void *s, uint64_t n, const void *dbase, const void *sbase) {
    const obj *od = access_obj(dbase, d, n), *os = access_obj(sbase, s, n);
    sh_move(d, s, n);
    if (inside(od, (uintptr_t)d, n) && inside(os, (uintptr_t)s, n)) { memmove(d, s, n); return; }
    unsigned char *tmp = malloc(n ? n : 1);
    __cqo_load(s, n, tmp, sbase);
    __cqo_store(d, n, tmp, dbase);
    free(tmp);
}

/* memset_pattern4/8/16 (pass/lib/calls/LibCalls.h): byte i of d is byte i % period of s, the shadow cells with it. */
void __cqo_imempattern(void *d, const void *s, uint64_t n, uint64_t period, const void *dbase, const void *sbase) {
    unsigned char *tmp = malloc(n ? n : 1);
    uint32_t *cells = malloc((n ? n : 1) * sizeof *cells);
    if (!tmp || !cells) { note("internal out of memory"); _exit(95); }
    for (uint64_t i = 0; i < n; ++i) {
        const unsigned char *b = (const unsigned char *)s + i % period;
        __cqo_load(b, 1, tmp + i, sbase);
        cells[i] = sh_get((uintptr_t)b);
    }
    __cqo_store(d, n, tmp, dbase);
    for (uint64_t i = 0; i < n; ++i) sh_put((uintptr_t)d + i, cells[i]);
    free(tmp);
    free(cells);
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
    if (p) heap_add(p, n), sh_clear(p, n);
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
    sh_move(q, p, old < n ? old : n);
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

/* ------------------------------------------------------------------ rule 2 classical collapse (cq-y1ll)
 * Owner ruling cq-r6bc (CR rule 2): a value computed only from measured rails and classical values is
 * classical, a data-flow condition and not a program-order one; a cq_measure of such a value is a
 * classical read and no gate. OracleInstr.cpp (shadows) gives every value the circuit holds as a rail
 * (taint's answer) a shadow node: a cq_theta result is a leaf, any other quantum value a fresh node
 * over the nodes it is computed from (operands, the cells it loads, the quantum conditions a merge
 * depends on, and SH_OPAQUE where the instrumentation cannot see a source: a value of an arm the
 * sample did not run). Node 0 is classical. A node is classical when it was measured, or when it is
 * no leaf and every node it depends on is classical. Memory cells (bytes) carry the node of the value
 * stored there; sh_gm is what any quantum load may also depend on (the conditions of quantum branches
 * whose arms write memory, stores at quantum addresses, library calls writing through pointers),
 * sh_gf the same for the fp environment, sh_mq every node ever stored. All of it is reset per sample. */
#define SH_OPAQUE 1u
#define SH_MAXN ((size_t)1 << 24)
#define SH_MAXD ((size_t)1 << 26)
#define SH_CELLS ((size_t)1 << 22)
#define SH_LEAF 1
#define SH_MEASURED 2
#define SH_CLASSICAL 4
static struct shnode { uint32_t d0, nd, stamp; uint8_t fl; } *sh_n;
static uint32_t *sh_d, *sh_stack;
static size_t sh_nn, sh_nd;
static uint32_t sh_stampv;
static struct shcell { uintptr_t a; uint32_t node, gen, ep; } *sh_c; /* ep: sh_gm when put */
static size_t sh_ncells;
static uint32_t sh_gm, sh_gf, sh_mq, sh_ret, sh_args[64];
static const void *sh_byval[64];
static int sh_pending_read;

#define SH_LO 4096
static struct shlo { uintptr_t p; uint64_t len; uint32_t node, c, ep, gm, gen; } *sh_lo; /* the loads measure may pin, off __DATA */
static uint32_t *sh_seen, *sh_genp; /* sh_genp: the cell generation, outside __DATA (never put back) */
/* The tables are mapped before the setup runs, so the snapshot of __DATA keeps their addresses. */
__attribute__((constructor(102))) static void sh_init(void) {
    if (sh_n) return;
    sh_n = mmap(0, SH_MAXN * sizeof *sh_n, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    sh_d = mmap(0, SH_MAXD * sizeof *sh_d, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    sh_stack = mmap(0, SH_MAXN * sizeof *sh_stack, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    sh_seen = mmap(0, SH_MAXN * sizeof *sh_seen, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    sh_c = mmap(0, SH_CELLS * sizeof *sh_c, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    sh_genp = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    sh_lo = mmap(0, SH_LO * sizeof *sh_lo, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (sh_n == MAP_FAILED || sh_d == MAP_FAILED || sh_stack == MAP_FAILED || sh_seen == MAP_FAILED ||
        sh_c == MAP_FAILED || sh_genp == MAP_FAILED || sh_lo == MAP_FAILED) {
        fprintf(stderr, "cqo: mmap\n");
        raise(SIGKILL);
    }
    *sh_genp = 1;
}

static void sh_reset(void) {
    sh_nn = 2, sh_nd = 0; /* 0: classical, 1: SH_OPAQUE */
    sh_n[0] = (struct shnode){0, 0, 0, SH_CLASSICAL};
    sh_n[SH_OPAQUE] = (struct shnode){0, 0, 0, SH_LEAF};
    if (++*sh_genp == 0) { memset(sh_c, 0, SH_CELLS * sizeof *sh_c); *sh_genp = 1; }
    sh_ncells = 0;
    sh_gm = sh_gf = sh_mq = sh_ret = 0;
    memset(sh_args, 0, sizeof sh_args);
    memset(sh_byval, 0, sizeof sh_byval);
    sh_pending_read = 0;
}

static uint32_t sh_new(const uint32_t *deps, unsigned k, uint8_t fl) {
    if (trips_only) return SH_OPAQUE;
    if (sh_nn < 2) sh_reset();
    if (sh_nn >= SH_MAXN || sh_nd + k > SH_MAXD) { note("internal more than %zu shadow nodes", (size_t)SH_MAXN); _exit(95); }
    uint32_t n = (uint32_t)sh_nn++;
    sh_n[n] = (struct shnode){(uint32_t)sh_nd, 0, 0, fl};
    for (unsigned i = 0; i < k; ++i)
        if (deps[i]) sh_d[sh_nd++] = deps[i], sh_n[n].nd++;
    return n;
}

/* a value's own node over up to three dependencies (0 when all are classical constants) */
uint32_t __cqo_sh_v(uint32_t a, uint32_t b, uint32_t c) {
    if (!(a | b | c)) return 0;
    uint32_t d[3] = {a, b, c};
    return sh_new(d, 3, 0);
}
/* a dependency set (no value of its own): 0, the single node, or a node over them */
uint32_t __cqo_sh_j(uint32_t a, uint32_t b, uint32_t c) {
    if (!(a | b | c)) return 0;
    if (!(b | c)) return a;
    if (!(a | c)) return b;
    if (!(a | b)) return c;
    uint32_t d[3] = {a, b, c};
    return sh_new(d, 3, 0);
}
/* a classical merge of a rail (OracleInstr.cpp, classical merges): a fresh node over the chosen
 * incoming's node, else (a constant incoming) a fresh node over the quantum incomings computed so far,
 * else SH_OPAQUE. The merge is a value of its own (cq-ndtt, cq-g72r: rule 2's static collapse is per
 * value; measuring the merge does not measure the incoming it chose on this sample), classical when the
 * chosen incoming is. */
uint32_t __cqo_sh_nz(uint32_t s, uint32_t inc) {
    if (s) return __cqo_sh_v(s, 0, 0);
    return inc ? __cqo_sh_v(inc, 0, 0) : SH_OPAQUE;
}
/* a frame slot of a quantum value: node + 1, 0 when not computed in this activation */
uint32_t __cqo_sh_slot(uint32_t v) { return v ? v - 1 : SH_OPAQUE; }
uint32_t __cqo_sh_slot0(uint32_t v) { return v ? v - 1 : 0; }
uint32_t __cqo_sh_leaf(void) { return sh_new(0, 0, SH_LEAF); }
uint32_t __cqo_sh_opaque(void) { return SH_OPAQUE; }

static int sh_classical(uint32_t n) {
    if (n == 0 || n >= sh_nn) return n == 0;
    uint32_t stamp = ++sh_stampv;
    size_t sp = 0, nseen = 0;
    sh_stack[sp++] = n;
    while (sp) {
        uint32_t m = sh_stack[--sp];
        struct shnode *x = &sh_n[m];
        if (x->fl & (SH_MEASURED | SH_CLASSICAL)) continue;
        if (x->fl & SH_LEAF) return 0;
        if (x->stamp == stamp) continue;
        x->stamp = stamp;
        sh_seen[nseen++] = m;
        for (uint32_t i = 0; i < x->nd; ++i) {
            if (sp == SH_MAXN) { note("internal shadow stack"); _exit(95); }
            sh_stack[sp++] = sh_d[x->d0 + i];
        }
    }
    for (size_t i = 0; i < nseen; ++i) sh_n[sh_seen[i]].fl |= SH_CLASSICAL;
    return 1;
}

/* cq_measure of a value with node n: a classical read when n is classical (no gate), else a
 * measurement. __cqo_site reads the verdict. CR rule 2, 406-408 (cq-ndtt): collapse is STATIC.
 * `every` (OracleInstr.cpp, the site's static answer for the frame's specialization) says whether the
 * measured value is measured on every path of its function: then n is classical from here on (the
 * outcome is n itself); otherwise n stays a rail and only the outcome is classical (the circuit
 * measures a basis copy of it, rule 2), a fresh measured node over n. Returns the outcome's node. */
static int sh_uniform(uintptr_t p, uint64_t len, uint32_t *node, uint32_t *ep);
static void sh_pin(uint32_t n);
static int sh_pending_collapse;
uint32_t __cqo_sh_measure(uint32_t n, int32_t every) {
    sh_pending_read = sh_classical(n);
    sh_pending_collapse = every != 0;
    if (sh_pending_read) return n;
    if (every) {
        if (n > SH_OPAQUE && n < sh_nn) sh_n[n].fl |= SH_MEASURED, sh_pin(n);
        return n;
    }
    return sh_new(&n, 1, SH_MEASURED);
}

/* The incoming a measured loop-carried value took this trip: the same rail, measured with it (only
 * when that measurement collapses and the incoming passes the same static test, cq-ndtt). */
void __cqo_sh_mark(uint32_t n, int32_t every) {
    if (!sh_pending_read && sh_pending_collapse && every && n > SH_OPAQUE && n < sh_nn) sh_n[n].fl |= SH_MEASURED, sh_pin(n);
}

/* memory cells, one per byte, open addressing; a cell of another generation is empty */
static struct shcell *sh_cell(uintptr_t a, int add) {
    size_t h = (size_t)((a * 0x9E3779B97F4A7C15ULL) >> 40) & (SH_CELLS - 1);
    for (;;) {
        struct shcell *c = &sh_c[h];
        if (c->gen != *sh_genp) {
            if (!add) return 0;
            if (sh_ncells * 10 >= SH_CELLS * 7) { note("internal more than %zu shadow cells", (size_t)SH_CELLS * 7 / 10); _exit(95); }
            sh_ncells++;
            c->a = a, c->gen = *sh_genp, c->node = 0, c->ep = 0;
            return c;
        }
        if (c->a == a) return c;
        h = (h + 1) & (SH_CELLS - 1);
    }
}
static uint32_t sh_get(uintptr_t a) { struct shcell *c = sh_ncells ? sh_cell(a, 0) : 0; return c ? c->node : 0; }
static void sh_put(uintptr_t a, uint32_t n) {
    if (trips_only) return;
    if (sh_nn < 2) { if (!n) return; sh_reset(); }
    struct shcell *c = sh_cell(a, n != 0);
    if (c) c->node = n, c->ep = sh_gm;
}
static void sh_clear(const void *p, uint64_t n) {
    if (!sh_ncells) return;
    for (uint64_t i = 0; i < n; ++i) sh_put((uintptr_t)p + i, 0);
}
static void sh_move(void *d, const void *s, uint64_t n) {
    if (!sh_ncells || !n) return;
    uint32_t buf[256];
    uint32_t *t = n <= 256 ? buf : malloc(n * sizeof *t);
    if (!t) { note("internal out of memory"); _exit(95); }
    for (uint64_t i = 0; i < n; ++i) t[i] = sh_get((uintptr_t)s + i);
    for (uint64_t i = 0; i < n; ++i) sh_put((uintptr_t)d + i, t[i]);
    if (t != buf) free(t);
}

void __cqo_sh_store(void *p, uint64_t n, uint32_t v, uint32_t addr) {
    if (addr) {
        v = __cqo_sh_j(v, addr, 0);
        sh_gm = __cqo_sh_j(sh_gm, v, 0);
    }
    if (v) sh_mq = __cqo_sh_j(sh_mq, v, 0);
    for (uint64_t i = 0; i < n; ++i) sh_put((uintptr_t)p + i, v);
}
/* Same rail (cq-425g, CR rule 2 with ABI 1.3: a second measurement of a rail is a classical
 * re-read). A load at a classical address of cells that all hold one node c, put while sh_gm was what
 * it is now (no quantum branch's implicit write since), is c itself. Otherwise it is a fresh node; when
 * the cells were uniform, the load remembers them (sh_lo), and a measurement of that node with the
 * cells and sh_gm unchanged pins it: the cells now hold the measured node, so a later load of them
 * reads the measured value (the rail measured in place). A rail load (`rail`: taint holds the value
 * as a rail) of a node-0 content is a fresh node over SH_OPAQUE: the circuit measures it, as a merge
 * of constants (OracleInstr.cpp, classical merges). */
static int sh_uniform(uintptr_t p, uint64_t len, uint32_t *node, uint32_t *ep) {
    for (uint64_t i = 0; i < len; ++i) {
        struct shcell *c = sh_ncells ? sh_cell(p + i, 0) : 0;
        uint32_t nn = c ? c->node : 0, ee = c ? c->ep : 0;
        if (i == 0) *node = nn, *ep = ee;
        else if (nn != *node || ee != *ep) return 0;
    }
    return 1;
}
static void sh_pin(uint32_t n) {
    struct shlo *r = &sh_lo[n % SH_LO];
    uint32_t c, ep;
    if (r->gen != *sh_genp || r->node != n || r->gm != sh_gm || !sh_uniform(r->p, r->len, &c, &ep) || c != r->c || ep != r->ep) return;
    for (uint64_t i = 0; i < r->len; ++i) sh_put(r->p + i, n);
}
static uint32_t sh_load(const void *p, uint64_t n, uint32_t addr, int rail) {
    uint32_t c = 0, ep = 0;
    int uni = !addr && n && sh_uniform((uintptr_t)p, n, &c, &ep);
    if (uni && ep == sh_gm && (c || !rail)) return c;
    uint32_t acc = __cqo_sh_j(addr, sh_gm, 0), last = 0;
    for (uint64_t i = 0; i < n; ++i) {
        uint32_t x = sh_get((uintptr_t)p + i);
        if (x && x != last) acc = __cqo_sh_j(acc, x, 0), last = x;
    }
    uint32_t r = acc ? __cqo_sh_v(acc, 0, 0) : rail ? __cqo_sh_v(SH_OPAQUE, 0, 0) : 0;
    if (uni && r > SH_OPAQUE) sh_lo[r % SH_LO] = (struct shlo){(uintptr_t)p, n, r, c, ep, sh_gm, *sh_genp};
    return r;
}
uint32_t __cqo_sh_load(const void *p, uint64_t n, uint32_t addr) { return sh_load(p, n, addr, 0); }
uint32_t __cqo_sh_qload(const void *p, uint64_t n, uint32_t addr) { return sh_load(p, n, addr, 1); }
uint32_t __cqo_sh_rload(const void *p, uint64_t n, uint32_t addr, int32_t rail) { return sh_load(p, n, addr, rail != 0); }
/* the frame's specialization chooses between two nodes (OracleInstr.cpp, railPick) */
uint32_t __cqo_sh_pick(uint32_t a, uint32_t b, int32_t rail) { return rail ? a : b; }
void __cqo_sh_fill(void *p, uint64_t n, uint32_t v) {
    if (v) sh_mq = __cqo_sh_j(sh_mq, v, 0);
    for (uint64_t i = 0; i < n; ++i) sh_put((uintptr_t)p + i, v);
}
void __cqo_sh_gm(uint32_t x) { sh_gm = __cqo_sh_j(sh_gm, x, 0); }
void __cqo_sh_gf(uint32_t x) { sh_gf = __cqo_sh_j(sh_gf, x, 0); }
uint32_t __cqo_sh_gm_get(void) { return sh_gm; }
uint32_t __cqo_sh_gf_get(void) { return sh_gf; }
uint32_t __cqo_sh_mq_get(void) { return sh_mq; }
void __cqo_sh_arg_set(int32_t i, uint32_t n) { if (i < 64) sh_args[i] = n; }
uint32_t __cqo_sh_arg(int32_t i) {
    if (i >= 64) return SH_OPAQUE;
    uint32_t n = sh_args[i];
    sh_args[i] = 0;
    return n;
}
void __cqo_sh_args_clear(void) { memset(sh_args, 0, sizeof sh_args); memset(sh_byval, 0, sizeof sh_byval); }
void __cqo_sh_ret_set(uint32_t n) { sh_ret = n; }
uint32_t __cqo_sh_ret(void) { uint32_t n = sh_ret; sh_ret = 0; return n; }
/* a byval argument: the callee's copy takes the cells of the caller's object */
void __cqo_sh_byval_src(int32_t i, const void *p) { if (i < 64) sh_byval[i] = p; }
void __cqo_sh_byval_in(int32_t i, void *p, uint64_t n) {
    const void *s = i < 64 ? sh_byval[i] : 0;
    if (i < 64) sh_byval[i] = 0;
    if (s) sh_move(p, s, n);
    else sh_clear(p, n);
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

static const char *kinds[] = {"theta", "phi", "measure", "invert_begin", "invert_end", "read"};

void __cqo_site(const char *fn, int32_t site, int32_t kind, uint64_t angle, void *reg, int32_t bits) {
    if (kind == 2 && sh_pending_read) kind = 5; /* rule 2: a classical read, no measurement (cq-y1ll) */
    sh_pending_read = 0;
    int sk = kind == 0 ? skey_of(fn, site) : -1;
    /* cq-3o3v: a theta site's register before the substitution (compare checks the lowered Ry's
     * target against it) */
    char pre[160] = "";
    if (kind == 0 && reg && !trips_only) {
        char h[140];
        hexbits(h, reg, (unsigned)bits);
        snprintf(pre, sizeof pre, ",\"pre\":\"%s\"", h);
    }
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
    if (trips_only) {               /* no site event in trip mode: only the counts the cutoff records read */
        if (kind == 2) n_measured++;
        else if (kind != 5) n_rotations++;
        return;
    }
    char f[300], a[40] = "null", r[64] = "null", line[800];
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
    snprintf(line, sizeof line, "{\"ev\":\"site\",\"fn\":%s,\"site\":%d,\"kind\":\"%s\",\"angle\":%s,\"reg\":%s%s}",
             f, site, kinds[kind], a, r, pre);
    out_line(trace_fd, line);
    if (kind == 2) n_measured++;
    else if (kind != 5) n_rotations++;
}

/* OracleInstr.cpp enters(): this input enters fn (compare._meas_extra) */
void __cqo_enter(const char *fn) {
    if (trips_only) return;
    char f[300], line[340];
    jsonstr(f, sizeof f, fn);
    snprintf(line, sizeof line, "{\"ev\":\"enter\",\"fn\":%s}", f);
    out_line(trace_fd, line);
}

/* Rulings Q3 (2026-11-11, part 2): a conditional branch whose arms not taken would reach the measurement sites `s` with
 * flags[i] set and the taken arm does not (OracleInstr.cpp Shadow::skips) logs them with whether the C run left them by a
 * quantum condition (q: the operands that decided the condition on this run, cq-nmzv3) and the branch's join id; the
 * join event marks its immediate post-dominator reached (cq-qotkl: the circuit runs the arms in sequence before it).
 * compare.py accepts an extra measurement of ours at a site only where the C run left its path by quantum conditions. */
int32_t __cqo_sh_isq(uint32_t node) { return !sh_classical(node); }
void __cqo_skip(int32_t q, const char *const *s, const int32_t *flags, int32_t n, int32_t j) {
    if (trips_only || n <= 0) return;
    char line[4000];
    int at = snprintf(line, sizeof line, "{\"ev\":\"skip\",\"q\":%d,\"j\":%d,\"s\":[", q != 0, j);
    int k = 0;
    for (int32_t i = 0; i < n && at < (int)sizeof line - 400; ++i) {
        if (!flags[i]) continue;
        char f[300];
        jsonstr(f, sizeof f, s[i]);
        at += snprintf(line + at, sizeof line - at, "%s%s", k++ ? "," : "", f);
    }
    if (!k) return;
    snprintf(line + at, sizeof line - at, "]}");
    out_line(trace_fd, line);
}
void __cqo_join(int32_t j) {
    if (trips_only) return;
    char line[64];
    snprintf(line, sizeof line, "{\"ev\":\"join\",\"j\":%d}", j);
    out_line(trace_fd, line);
}

/* cq-xidq (CR rule 12, §6's global phases): the quantum scope a frame was called in (OracleInstr.cpp Shadow::phaseScope).
 * A cq_phi reached with a quantum predicate in scope (rule 2's static collapse) logs `phq` just before its site event. */
static int32_t qs_next;
void __cqo_qs_set(int32_t q) { qs_next = q != 0; }
int32_t __cqo_qs_get(void) { return qs_next; }
int32_t __cqo_qcond(uint32_t node) { return !sh_classical(node); }
void __cqo_phq(int32_t q) {
    if (trips_only || !q) return;
    out_line(trace_fd, "{\"ev\":\"phq\"}");
}

/* ------------------------------------------------------------------ the cutoff K (CR §6, cq-8ay)
 * OracleInstr.cpp passes kq = 1 where the loop is a quantum-exit loop in the running specialization.
 * Each activation of one gets a T2 record when it ends: by an exit edge (capped false), or when the
 * trip counter reaches K+1 trips begun (capped true, n = K, cut/mcut = entries so far); the capped
 * one ends the sample. A quantum-depth recursion counts its `_ctl` activations per function (below). */
int32_t __cqo_spec_next; /* the callee's specialization id; -1: the driver's call (its entry spec) */

/* An activation's identity, the same on every sample that reaches it: the call sites leading to it and the how-many-th there.
 * A count over the whole sample would name another activation whenever a quantum arm the C program skips holds an earlier one,
 * and the circuit makes both whatever the arm (rule 14: one a_K of its own; cq-rdsdj). */
#define MAXACT 1024
static struct { const char *id; uint64_t path; long n; } acts[MAXACT];
static int nacts;
static uint64_t act_path;

int64_t __cqo_path_enter(int64_t site) {
    uint64_t saved = act_path;
    act_path = (act_path ^ (uint64_t)site) * UINT64_C(0x100000001b3);
    return (int64_t)saved;
}
void __cqo_path_leave(int64_t saved) { act_path = (uint64_t)saved; }

static long next_act(const char *id, uint64_t path) {
    long n = 0;
    int i;
    for (i = 0; i < nacts; ++i)
        if (acts[i].path == path && !strcmp(acts[i].id, id)) { n = acts[i].n++; break; }
    if (i == nacts) {
        if (nacts == MAXACT) { note("internal more than %d cutoff activations", MAXACT); _exit(95); }
        acts[nacts].id = id, acts[nacts].path = path, acts[nacts].n = 1;
        nacts++;
    }
    return (long)((path ^ (uint64_t)n * UINT64_C(0x9E3779B97F4A7C15)) >> 1);
}

/* trip mode: the (loop, n, kind) pairs written so far in this sample (__DATA: put back per sample) */
#define TSEEN 4096
static struct { const char *id; long long n; int kind; } tseen[TSEEN];
static int ntseen;
static int trip_seen(const char *id, long long n, int kind) {
    for (int i = 0; i < ntseen; ++i)
        if (tseen[i].id == id && tseen[i].n == n && tseen[i].kind == kind) return 1;
    if (ntseen < TSEEN) tseen[ntseen].id = id, tseen[ntseen].n = n, tseen[ntseen].kind = kind, ntseen++;
    return 0;
}

static uint64_t ticks;
static void kloop_record(const char *id, long long n, int capped, uint64_t path) {
    char l[300], line[600];
    if (trips_only && !capped && trip_seen(id, n, 1)) { next_act(id, path); return; }
    jsonstr(l, sizeof l, id);
    long act = next_act(id, path);
    if (capped)
        snprintf(line, sizeof line,
                 "{\"ev\":\"kloop\",\"loop\":%s,\"act\":%ld,\"n\":%lld,\"capped\":true,\"cut\":%ld,\"mcut\":%ld}",
                 l, act, n, n_rotations, n_measured);
    else
        snprintf(line, sizeof line, "{\"ev\":\"kloop\",\"loop\":%s,\"act\":%ld,\"n\":%lld,\"capped\":false}",
                 l, act, n);
    out_line(trace_fd, line);
}

static void kcap(const char *id, long long K, uint64_t path) {
    kloop_record(id, K, 1, path);
    note("cap %s", id);
    _exit(0);
}

void __cqo_trip(const char *loop, int64_t n, int32_t kq) {
    char l[300], line[400];
    if (!trips_only || !trip_seen(loop, n, 0)) {
        jsonstr(l, sizeof l, loop);
        if (trips_only)
            snprintf(line, sizeof line, "{\"ev\":\"trip\",\"loop\":%s,\"n\":%lld,\"h\":%llu}", l, (long long)n,
                     (unsigned long long)ticks);
        else
            snprintf(line, sizeof line, "{\"ev\":\"trip\",\"loop\":%s,\"n\":%lld}", l, (long long)n);
        out_line(trace_fd, line);
    }
    if (kq) kloop_record(loop, n, 0, act_path);
}

/* cnt trips begun (the counter after this header run, or before entering the body of a loop that
 * tests at its header): one more than K means the exit test after the K-th body admitted trip K+1. */
static int64_t k_recv; /* the K a table clone received (rule 19: the caller's; rule 27: its by-name callees too), 0: none */
void __cqo_kcheck(const char *loop, int64_t cnt, int64_t K, int32_t kq) {
    if (k_recv) K = k_recv;
    if (kq && cnt > K) kcap(loop, K, act_path);
}

/* CR rule 14, §1.4: only `_ctl` activations count, per function: an activation reads d, the live `_ctl` activations of its
 * function, and is cut at d = K. The one that enters with no quantum predicate in scope does not count, so up to K bodies
 * run under a quantum predicate either way, and the (K+1)-th `_ctl` activation is the cut. */
#define MAXREC 64
#define RECFN 16
static struct { const char *id; uint64_t path; long long max; int nfn; struct { const char *fn; long long d; } fn[RECFN]; } recs[MAXREC];
static int nrecs;

static long long *rec_count(const char *fn) {
    int top = nrecs - 1;
    for (int i = 0; i < recs[top].nfn; ++i)
        if (!strcmp(recs[top].fn[i].fn, fn)) return &recs[top].fn[i].d;
    if (recs[top].nfn == RECFN) { note("internal more than %d functions on one call cycle", RECFN); _exit(95); }
    recs[top].fn[recs[top].nfn].fn = fn, recs[top].fn[recs[top].nfn].d = 0;
    return &recs[top].fn[recs[top].nfn++].d;
}

void __cqo_rec_enter(const char *id, int32_t on, int32_t ctl) {
    if (!on) return;
    if (nrecs == MAXREC) { note("internal recursion activations nested deeper than %d", MAXREC); _exit(95); }
    recs[nrecs].id = id, recs[nrecs].path = act_path, recs[nrecs].max = ctl ? 1 : 0, recs[nrecs].nfn = 0;
    nrecs++;
    if (ctl) *rec_count(id) = 1;
}

void __cqo_rec_exit(int32_t on) {
    if (!on) return;
    if (nrecs == 0) { note("internal recursion exit outside an activation"); _exit(95); }
    nrecs--;
    kloop_record(recs[nrecs].id, recs[nrecs].max, 0, recs[nrecs].path);
}

void __cqo_rec_down(const char *fn, int64_t K, int32_t on) {
    if (!on) return;
    if (nrecs == 0) { note("internal recursion level outside an activation"); _exit(95); }
    if (k_recv) K = k_recv;
    long long *d = rec_count(fn);
    if (*d >= K) kcap(recs[nrecs - 1].id, K, recs[nrecs - 1].path);
    ++*d;
    if (*d > recs[nrecs - 1].max) recs[nrecs - 1].max = *d;
}

void __cqo_rec_up(const char *fn, int32_t on) {
    if (on && nrecs) --*rec_count(fn);
}

/* An indirect call (rule 19). K is the K of the caller's enclosing function, read by the table clone and what it calls by
 * name; an activation the table clone entered ends with the call. Returns what __cqo_ptr_leave puts back. */
int64_t __cqo_ptr_enter(int64_t K) {
    int64_t saved = (k_recv << 8) | nrecs;
    if (!k_recv) k_recv = K;
    return saved;
}

void __cqo_ptr_leave(int64_t saved) {
    while (nrecs > (int)(saved & 0xff)) __cqo_rec_exit(1);
    k_recv = saved >> 8;
}

/* the step budget: loop-header executions of one sample (the setup's do not count; cq-u9al) */
static uint64_t tripcap = 10000000;
static void tick_progress(void);
static void stdout_room(void);
void __cqo_tick(void) {
    if (++ticks > tripcap) { note("tripcap"); _exit(98); }
    if (!(ticks & 0xffff)) stdout_room();
    if (!(ticks & 0xfffff)) tick_progress();
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
 * default ("wait signaled 6"); in-process, with a jump back to the driver. A crash, the hang guard
 * (SIGPROF) or any other signal ends the worker after its notes; the server writes the "wait" note of a
 * worker that died inside a sample and forks a fresh worker for the next record, so that sample's end
 * is exactly the fork-per-sample one. Isolated modules (oracle.py: process state the restore does not
 * cover, such as signal handlers, atexit or rand) run every sample in a worker of its own, and their
 * exit and abort are the C library's. A sample whose allocation passes the arena also ends its worker.
 *
 *   prog <trace> <status> <timeout_ms> <tripcap> [<subst>]          one batch ($CQD_SAMPLES)
 *   prog --serve                                                     a batch per stdin line:
 *       <trace> <status> <err> <timeout_ms> <tripcap> <isolate 0|1> <samples> <subst|-> [<trip mode 0|1>]
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
    int cap_set;              /* cap_n is known (the server's first record) */
    off_t cap_n;              /* the setup's part of the stdout file */
    volatile int trace_over;  /* a worker found the trace past $CQO_TRACE_MAX (cq-3fjt) */
};
static struct shot *R;
static int is_worker; /* set before the snapshot: stays set */

static int sample_running(void) { return is_worker && R->in_sample; }
/* a sample that executes loop headers makes progress (the wall-clock backstop below): one past a
 * minute of wall time is a long run, not a hang (cq-g8md: the witness runs past the budget) */
static void tick_progress(void) { if (R && is_worker) R->progress++; }
static void mark_dirty(void) { if (R) R->dirty = 1; }

static void die(const char *what) {
    fprintf(stderr, "cqo: %s: %s\n", what, strerror(errno));
    real__exit(2);
}

/* Disk caps (cq-3fjt: one evaluator run's trace once reached 15 GB). A batch whose trace would pass
 * $CQO_TRACE_MAX bytes (default 128 MiB; 0: no cap) ends with status 95 and a message on its stderr:
 * oracle.py raises OracleError, an internal error of the checker and never a sample outcome. A worker
 * that finds it so marks R and ends; its server ends the batch (server_wait). RLIMIT_FSIZE
 * ($CQO_FILE_MAX, default 256 MiB, SIGXFSZ ignored) is the backstop for every file the batch writes,
 * and a sample whose stdout passes CAP_RAW stops at the next 65536th loop header with the "internal
 * stdout" note it would have got at its end. */
static unsigned long long trace_max = 128ULL << 20;

static int trace_room(size_t n) {
    struct stat st;
    if (!trace_max || trace_fd < 0 || fstat(trace_fd, &st) != 0 || (unsigned long long)st.st_size + n <= trace_max)
        return 1;
    if (R) R->trace_over = 1;
    fprintf(stderr, "cqo: cq-3fjt: the batch's trace would pass %llu bytes ($CQO_TRACE_MAX)\n", trace_max);
    real__exit(95);
}

static unsigned long long env_bytes(const char *name, unsigned long long dflt) {
    const char *v = getenv(name);
    return v && *v ? strtoull(v, 0, 10) : dflt;
}

/* -- host output (cq-e4jk) -- */
#define CAP_RAW ((size_t)1 << 16)          /* a sample's stdout beyond this is an internal note */
#define BIG_CAP (CAP_RAW * 6 + 4096)       /* one escaped line */
static int cap_fd = -1;                    /* the batch's stdout file (fd 1 is a dup of it) */
static char *bigline;                      /* mmap'd once per batch: never put back, never in __DATA */
static char fxline[8192];
static size_t fxn;
static int fx_on;

/* One `<index>\t<s>\n` trace line of any length (out_line caps at 4096 bytes). */
static void out_long(const char *s, size_t n) {
    char pre[32];
    int k = snprintf(pre, sizeof pre, "%ld\t", cur_sample);
    obuf *o = ob_trace;
    if (trace_fd < 0 || k < 0) return;
    size_t tot = (size_t)k + n + 1;
    if (!o || tot > OBUF_CAP) {
        if (o) ob_flush(o, trace_fd);
        trace_room(tot);
        /* one write: other writers append to the same file */
        char *b = bigline + BIG_CAP;
        memcpy(b, pre, (size_t)k), memcpy(b + k, s, n), b[k + n] = '\n';
        write_all(trace_fd, b, tot);
        return;
    }
    if (o->n + tot > OBUF_CAP) ob_flush(o, trace_fd);
    memcpy(o->b + o->n, pre, (size_t)k);
    memcpy(o->b + o->n + k, s, n);
    o->b[o->n + k + n] = '\n';
    o->n += tot;
}

/* JSON string body of n bytes, each byte the code point of the same number (rt_tape.c's convention). */
static size_t esc_bytes(char *out, const unsigned char *p, size_t n) {
    size_t m = 0;
    for (size_t i = 0; i < n; ++i) {
        unsigned char c = p[i];
        if (c == '"' || c == '\\') out[m++] = '\\', out[m++] = (char)c;
        else if (c == '\n') out[m++] = '\\', out[m++] = 'n';
        else if (c < 0x20 || c >= 0x7f) m += (size_t)sprintf(out + m, "\\u%04x", c);
        else out[m++] = (char)c;
    }
    return m;
}

/* The sample's stdout as one trace line; the file goes back to the setup's part. */
static void emit_stdout(void) {
    if (cap_fd < 0 || !bigline || !R) return;
    fflush(stdout);
    struct stat st;
    if (fstat(cap_fd, &st) != 0) { note("internal stdout: fstat: %s", strerror(errno)); return; }
    size_t n = (size_t)st.st_size;
    if (n > CAP_RAW) { note("internal stdout: the sample printed %zu bytes (more than %zu)", n, CAP_RAW); n = CAP_RAW; }
    unsigned char *raw = (unsigned char *)bigline + 2 * BIG_CAP;
    size_t got = 0;
    while (got < n) {
        ssize_t r = pread(cap_fd, raw + got, n - got, (off_t)got);
        if (r < 0 && errno == EINTR) continue;
        if (r <= 0) { note("internal stdout: pread: %s", r < 0 ? strerror(errno) : "short"); return; }
        got += (size_t)r;
    }
    size_t m = (size_t)sprintf(bigline, "{\"ev\":\"stdout\",\"s\":\"");
    m += esc_bytes(bigline + m, raw, n);
    m += (size_t)sprintf(bigline + m, "\"}");
    out_long(bigline, m);
    if (ftruncate(cap_fd, R->cap_n) != 0) note("internal stdout: ftruncate: %s", strerror(errno));
}

/* cq-3fjt: a sample's stdout past CAP_RAW ends it now with the note emit_stdout gives at its end. */
static void stdout_room(void) {
    struct stat st;
    if (cap_fd < 0 || !R || !sample_running() || fstat(cap_fd, &st) != 0) return;
    size_t n = (size_t)st.st_size;
    if (n > CAP_RAW + (size_t)R->cap_n) {
        note("internal stdout: the sample printed %zu bytes (more than %zu)", n - (size_t)R->cap_n, CAP_RAW);
        _exit(95);
    }
}

/* The batch's stdout: a file of its own (unlinked), fd 1, unbuffered. */
static void stdout_capture(const char *trace) {
    char path[4200];
    snprintf(path, sizeof path, "%s.stdout", trace);
    cap_fd = open(path, O_RDWR | O_CREAT | O_TRUNC | O_APPEND, 0644);
    if (cap_fd < 0) die("open the stdout file");
    unlink(path);
    if (dup2(cap_fd, 1) < 0) die("dup2 stdout");
    setvbuf(stdout, 0, _IONBF, 0);
    void *m = mmap(0, 3 * BIG_CAP, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (m == MAP_FAILED) die("mmap");
    bigline = m;
}

/* The effect hooks (OracleInstr.cpp, logEffect): begin, one call per argument, end. */
void __cqo_fx_begin(const char *name) {
    fx_on = sample_running();
    if (!fx_on) return;
    fxn = (size_t)snprintf(fxline, sizeof fxline, "{\"ev\":\"effect\",\"name\":\"%s\",\"args\":[", name);
}
static void fx_sep(void) { if (fxline[fxn - 1] != '[') fxline[fxn++] = ','; }
void __cqo_fx_str(const char *p) {
    if (!fx_on) return;
    size_t n = p ? strnlen(p, 1024) : 0;
    if (fxn + n * 6 + 32 > sizeof fxline) { note("internal effect: argument too long"); fx_on = 0; return; }
    fx_sep();
    fxn += (size_t)sprintf(fxline + fxn, "{\"s\":\"");
    fxn += esc_bytes(fxline + fxn, (const unsigned char *)p, n);
    fxn += (size_t)sprintf(fxline + fxn, "\"}");
}
void __cqo_fx_int(uint64_t v, int32_t bits) {
    if (!fx_on) return;
    if (fxn + 64 > sizeof fxline) { note("internal effect: too many arguments"); fx_on = 0; return; }
    fx_sep();
    fxn += (size_t)sprintf(fxline + fxn, "{\"w\":\"i%d\",\"v\":\"0x%llx\"}", (int)bits, (unsigned long long)v);
}
void __cqo_fx_end(void) {
    if (!fx_on) return;
    fxn += (size_t)sprintf(fxline + fxn, "]}");
    out_long(fxline, fxn);
    fx_on = 0;
}
/* Rulings Q2 (owner 2026-11-11, cq-auqs3): a bodiless callee (a direct host call, fx_call.h) given a pointer into an
 * object of the C program that holds a rail at the call. The object is the real one (the object table: the allocas,
 * byval copies, va areas, heap blocks and globals, find_obj); no object, no event. A cell holds a rail when its
 * shadow node (rule 2 above: a value the circuit holds as a rail) is not classical. A cell made QUANTUM only by an
 * implicit write (a classical value stored under a quantum condition: sh_gm, not the cell) is not seen here: such a
 * sample is compared. Logged as {"ev":"q2","name","addr","lo","hi"}: oracle.py outputs["q2"], the ruling's decision
 * (compare.py), which no lowering can widen. Reach through a global or a stored pointer is not followed (the
 * ruling's stated limit). */
static int q2_rail_cell(uintptr_t lo, uintptr_t hi) {
    if (!sh_ncells || sh_nn < 2) return 0;
    if (hi - lo <= ((uintptr_t)1 << 16)) {
        for (uintptr_t x = lo; x < hi; ++x) {
            uint32_t n = sh_get(x);
            if (n && !sh_classical(n)) return 1;
        }
        return 0;
    }
    for (size_t i = 0; i < SH_CELLS; ++i)
        if (sh_c[i].gen == *sh_genp && sh_c[i].a >= lo && sh_c[i].a < hi && sh_c[i].node && !sh_classical(sh_c[i].node))
            return 1;
    return 0;
}
static void __cqo_q2_check(const char *name, uintptr_t a) {
    if (!a || trips_only || !sample_running()) return;
    const obj *o = find_obj(a);
    if (!o || !q2_rail_cell(o->lo, o->hi)) return;
    char b[256];
    int m = snprintf(b, sizeof b, "{\"ev\":\"q2\",\"name\":\"%.120s\",\"addr\":\"0x%llx\",\"lo\":\"0x%llx\",\"hi\":\"0x%llx\"}",
                     name ? name : "", (unsigned long long)a, (unsigned long long)o->lo, (unsigned long long)o->hi);
    out_long(b, (size_t)m);
}
#define FX_PTR_HOOK(name, p) __cqo_q2_check((name), (uintptr_t)(p))
/* A direct host call: the stand-in, one source with the evaluator (fx_call.h; rulings Q8). */
#define FX_LOG(line, n) do { if (sample_running()) out_long(line, n); } while (0)
#define CQ_FX_REALLOC __cqo_realloc /* ruling Q5: getline's buffer and fgetln's line are heap objects of the program */
#include "fx_call.h"

/* The named outputs in memory (CR §6 item 1; drivers.py "Driver objects"): one object's bytes, a little-endian
 * hex value `w` = i<8n> wide. Host memory is the C program's memory: a plain read. */
void __cqo_out_mem(const char *name, const void *addr, uint64_t n) {
    if (!sample_running() || !bigline) return;
    if (2 * n + 512 > BIG_CAP) { note("internal out_mem: object %s of %llu bytes", name, (unsigned long long)n); return; }
    size_t m = (size_t)sprintf(bigline, "{\"ev\":\"out_mem\",\"name\":\"%s\",\"addr\":\"0x%llx\",\"w\":\"i%llu\",\"v\":\"0x",
                               name, (unsigned long long)(uintptr_t)addr, (unsigned long long)n * 8);
    for (uint64_t i = n; i-- > 0;) m += (size_t)sprintf(bigline + m, "%02x", ((const unsigned char *)addr)[i]);
    if (!n) bigline[m++] = '0';
    m += (size_t)sprintf(bigline + m, "\"}");
    out_long(bigline, m);
}
void __cqo_out_object(const char *name, const void *addr, uint64_t n) {
    if (!sample_running()) return;
    char b[512];
    int m = snprintf(b, sizeof b, "{\"ev\":\"object\",\"name\":\"%s\",\"addr\":\"0x%llx\",\"size\":%llu}", name,
                     (unsigned long long)(uintptr_t)addr, (unsigned long long)n);
    out_long(b, (size_t)m);
}
/* Rail-sized allocations (CR §6, rule 16; oracle.py _k2_sites): the block is K2 bytes, and the size goes to the trace. */
static void k2_note(uint64_t n, uint64_t k2) {
    if (!sample_running()) return;
    char b[96];
    int m = snprintf(b, sizeof b, "{\"ev\":\"k2\",\"n\":%llu,\"k2\":%llu}", (unsigned long long)n, (unsigned long long)k2);
    out_long(b, (size_t)m);
}
void *__cqo_malloc_k2(size_t n, size_t k2) { k2_note(n, k2); return __cqo_malloc(n > k2 ? k2 : n); }
void *__cqo_calloc_k2(size_t c, size_t n, size_t k2) {
    size_t t = c && n > (size_t)-1 / c ? (size_t)-1 : c * n;
    k2_note(t, k2);
    return __cqo_malloc(t > k2 ? k2 : t);
}
void *__cqo_aligned_alloc_k2(size_t al, size_t n, size_t k2) { k2_note(n, k2); return heap_alloc(al, n > k2 ? k2 : n); }
void *__cqo_realloc_k2(void *p, size_t n, size_t k2) { k2_note(n, k2); return __cqo_realloc(p, n > k2 ? k2 : n); }

/* The ranges a pointer the program made may lie in (compare.py "Pointers"). */
void __cqo_out_regions(void) {
    if (!sample_running()) return;
    char b[256];
    uintptr_t sp = (uintptr_t)__builtin_frame_address(0);
    int m = snprintf(b, sizeof b, "{\"ev\":\"region\",\"name\":\"stack\",\"lo\":\"0x%llx\",\"hi\":\"0x%llx\"}",
                     (unsigned long long)(sp - ((uintptr_t)8 << 20)), (unsigned long long)(sp + ((uintptr_t)1 << 16)));
    out_long(b, (size_t)m);
    if (arena_base) {
        m = snprintf(b, sizeof b, "{\"ev\":\"region\",\"name\":\"heap\",\"lo\":\"0x%llx\",\"hi\":\"0x%llx\"}",
                     (unsigned long long)(uintptr_t)arena_base, (unsigned long long)(uintptr_t)arena_top);
        out_long(b, (size_t)m);
    }
}

static void *sys_alloc(size_t n) {
    void *p = malloc(n ? n : 1);
    if (!p) die("out of memory");
    return p;
}

static void timer_ms(int which, long ms, int periodic) {
    struct itimerval it;
    memset(&it, 0, sizeof it);
    if (ms > 0) {
        it.it_value.tv_sec = ms / 1000, it.it_value.tv_usec = (ms % 1000) * 1000;
        if (periodic) it.it_interval = it.it_value;
    }
    setitimer(which, &it, 0);
}
/* the server's wall-clock backstop: a worker that makes no progress (no sample begins or ends) for
 * this long, in CPU or not, is killed and reported as a hang (an internal error, never an outcome) */
#define HANG_WALL_MS 60000L

/* the worker leaves (a crash, a timeout, a dirty or isolated sample): its output, then the end */
static void worker_leave(void) {
    ob_flush(ob_trace, trace_fd);
    ob_flush(ob_status, status_fd);
    real__exit(0);
}

/* A sample's in-process end: the driver's sigsetjmp returns again (__cqo_resume). */
__attribute__((noreturn)) static void sample_jump(void) { siglongjmp(R->jb, 1); }
/* CR rule 24: a longjmp outside the pairing under a quantum predicate is rule 16's noreturn arm (OracleInstr, ArmJumps). */
void __cqo_longjmp_arm(int32_t on) { if (on) { note("noreturn longjmp"); sample_jump(); } }

/* An isolated sample that ends before its outputs leaves the process, so it never reaches the driver's sigsetjmp, where the
 * others give their address table (oracle.py BEFORE_CALL; CR §6: pointer fields read relationally). */
void __cqo_out_table(void);
/* The sample's final exception flags, rule 23's output (compare._leaks; meaningful where the program touches the environment:
 * OracleInstr.cpp defaultEnv keeps every other operation's flags out). */
static void out_final_flags(void) {
    char line[48];
    snprintf(line, sizeof line, "{\"ev\":\"fenv\",\"flags\":%d}", fetestexcept(CQO_FE_IEEE));
    out_line(trace_fd, line);
}
static void isolated_table(void) {
    if (!isolate || trips_only || !sample_running()) return;
    out_final_flags();
    __cqo_out_table();
    __cqo_out_regions();
}
void exit(int code) {
    if (sample_running() && !isolate) { note("wait exited %d", code & 0xff); sample_jump(); }
    isolated_table();
    real_exit(code);
}
void _exit(int code) {
    if (sample_running() && !isolate) { note("wait exited %d", code & 0xff); sample_jump(); }
    isolated_table();
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
    isolated_table();
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
    if (!sample_running()) { signal(SIGPROF, SIG_DFL); raise(SIGPROF); return; }
    note("hang cpu %ld", timeout_ms);
    R->next = R->cur + 1;
    R->in_sample = 0;
    worker_leave();
}

/* Owner ruling 2026-11-12 cq-silnj: a signal number is valid when 1 <= sig <= 64 and it is none of 9, 19, 32, 33, 34
 * (musl's sigaction test plus the kernel's refusal of SIGKILL and SIGSTOP), never by the host's (macOS) numbering. CR rule
 * 16's signal table: one cell per valid number, SIG_DFL (0) until the program registers a function. A program that calls
 * signal runs every sample in a worker of its own (oracle.py _ISOLATE), so the cells start at SIG_DFL in each sample. */
static void (*sig_cell[65])(int);
static int sig_valid(int32_t s) { return s >= 1 && s <= 64 && s != 9 && s != 19 && s != 32 && s != 33 && s != 34; }

/* The C program's raise(sig) (OracleInstr.cpp notes() sends a direct call of the declared raise here). CR rule 16's
 * signal table: raise calls the function registered for sig (its cell, then 0, as musl's raise returns after the
 * handler); the complement (no registered function: the default action or no handler, an invalid sig included) is the
 * effect entry raise with sig as its one field, logged as rt_tape.c logs ours, no host call, its result musl's (owner
 * ruling 2026-11-12 cq-dbtpi: 0 for 0 <= sig <= 64, else -1; fx_call.h fxc_output_value). A handler installed with
 * sigaction, outside the cells, is the program's when it is neither SIG_DFL, SIG_IGN nor one this runtime installed
 * (on_crash, on_timeout); the host's raise then runs it, as the C program does. */
/* The C program's signal(sig, h) (OracleInstr.cpp notes()): CR rule 16's signal table over ruling cq-silnj's numbers. An
 * invalid sig returns SIG_ERR, stores EINVAL to the program's errno (sig_errloc: the module's own __errno_location, which
 * __cqo_signal_errloc passes right before the call and which is called only then, or null when the module defines none;
 * the host's errno too) and registers nothing; a valid one returns its cell's previous content and
 * stores h there. Where the host has the signal, h is also installed there, so that a delivery runs it as before. */
static int32_t *(*sig_errloc)(void);
void __cqo_signal_errloc(int32_t *(*f)(void)) { sig_errloc = f; }
void (*__cqo_signal(int32_t sig, void (*h)(int)))(int) {
    if (!sig_valid(sig)) {
        if (sig_errloc) *sig_errloc() = EINVAL;
        errno = EINVAL;
        return SIG_ERR;
    }
    void (*r)(int) = sig_cell[sig];
    sig_cell[sig] = h;
    if (sig < NSIG && sig != SIGKILL && sig != SIGSTOP) signal(sig, h);
    return r;
}

int32_t __cqo_raise(int32_t sig) {
    if (sig_valid(sig)) {
        void (*h)(int) = sig_cell[sig];
        if (h && h != SIG_IGN && h != SIG_ERR) {
            struct sigaction cur;
            if (sig < NSIG && sigaction(sig, 0, &cur) == 0 && !(cur.sa_flags & SA_SIGINFO) && cur.sa_handler == h)
                return raise(sig);
            h(sig);
            return 0;
        }
    }
    struct sigaction cur;
    if (sig > 0 && sig < NSIG && sigaction(sig, 0, &cur) == 0) {
        int own = (cur.sa_flags & SA_SIGINFO) ? cur.sa_sigaction == on_crash
                                              : cur.sa_handler == SIG_DFL || cur.sa_handler == SIG_IGN || cur.sa_handler == on_timeout;
        if (!own) return raise(sig);
    }
    cqd_fxc_begin("raise");
    cqd_fxc_int((uint32_t)sig, 0, 32, "i32");
    return (int32_t)cqd_fxc_done(32);
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
    if (arena_base && arena_top > arena_base) {
        /* cq-oou2: a large block (75's malloc(n * 4) with n near 2^30) is replaced by fresh zero pages,
         * never written: zeroing it touched every page (gigabytes) though the sample used a few */
        size_t used = (size_t)(arena_top - arena_base);
        if (used <= ((size_t)1 << 20)) memset(arena_base, 0, used);
        else {
            size_t pg = (size_t)getpagesize(), len = (used + pg - 1) & ~(pg - 1);
            if (mmap(arena_base, len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON | MAP_FIXED, -1, 0) == MAP_FAILED)
                die("mmap");
        }
    }
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
    timer_ms(ITIMER_REAL, HANG_WALL_MS, 1);
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
    timer_ms(ITIMER_REAL, 0, 0);
    if (R->trace_over) {
        fprintf(stderr, "cqo: cq-3fjt: the batch's trace would pass %llu bytes ($CQO_TRACE_MAX)\n", trace_max);
        real__exit(95);
    }
    ob_flush(&R->tr, trace_fd); /* what the worker left unwritten (whole lines) */
    ob_flush(&R->st, status_fd);
    if (!R->in_sample) { R->resume = R->next; return; }
    cur_sample = R->cur;
    emit_stdout();
    if (killed) note("hang wall");
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
    timer_ms(ITIMER_REAL, 0, 0); /* the server's tick is not the worker's */
    signal(SIGALRM, SIG_DFL);
    int devnull = open("/dev/null", O_WRONLY);
    if (devnull >= 0) dup2(devnull, 2), close(devnull); /* fd 1 stays the batch's stdout file (cq-e4jk) */
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
    sigaction(SIGPROF, &sa, 0);
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
        if (!R->cap_set && cap_fd >= 0) {
            struct stat st;
            R->cap_n = fstat(cap_fd, &st) == 0 ? st.st_size : 0;
            R->cap_set = 1;
        }
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
    ticks = 0;
    sh_reset();
    __cqo_spec_next = -1; /* the driver's call enters its callee's entry specialization */
    stack_save((char *)__builtin_frame_address(0) + 16);
    R->progress++;
    R->in_sample = 1;
    timer_ms(ITIMER_PROF, timeout_ms, 0);
    return 1;
}

static void sample_finish(void) {
    timer_ms(ITIMER_PROF, 0, 0);
    if (trips_only) {
        char line[80];
        snprintf(line, sizeof line, "{\"ev\":\"ticks\",\"n\":%llu}", (unsigned long long)ticks);
        out_line(trace_fd, line);
    } else {
        out_final_flags();
    }
    emit_stdout();
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
    trace_max = env_bytes("CQO_TRACE_MAX", trace_max);
    unsigned long long fmax = env_bytes("CQO_FILE_MAX", 256ULL << 20);
    struct rlimit rl;
    if (fmax && getrlimit(RLIMIT_FSIZE, &rl) == 0 && (rl.rlim_cur == RLIM_INFINITY || rl.rlim_cur > fmax)) {
        rl.rlim_cur = rl.rlim_max != RLIM_INFINITY && rl.rlim_max < fmax ? rl.rlim_max : (rlim_t)fmax;
        setrlimit(RLIMIT_FSIZE, &rl);
    }
    signal(SIGXFSZ, SIG_IGN); /* a write past the limit fails (EFBIG); trace_room says so first */
    trace_fd = open(trace, O_WRONLY | O_CREAT | O_APPEND | O_TRUNC, 0644);
    status_fd = open(status, O_WRONLY | O_CREAT | O_APPEND | O_TRUNC, 0644);
    if (trace_fd < 0 || status_fd < 0) { perror("cqo"); return 2; }
    stdout_capture(trace);
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
        int iso, tmode = 0;
        int nf = sscanf(line, "%2047s %2047s %2047s %ld %llu %d %2047s %2047s %d", tr, stp, err, &to, &cap, &iso, smp, sub,
                        &tmode);
        if (nf != 8 && nf != 9) {
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
            timeout_ms = to, tripcap = cap, isolate = iso, trips_only = tmode;
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

/* fptrunc fp128 -> x86_fp80, reached by sitofp/uitofp from more than 128 bits through LLVM 19's
 * ExpandLargeFpConvert. Darwin's libclang_rt.osx.a ships trunctfxf2.c.o empty, so the oracle program
 * does not link without it. CR §2: a library step, IEEE; the oracle runs a plain conversion in the
 * default environment, so to nearest even (finite inputs: the expansion builds no NaN or Inf). The
 * fp128 travels in xmm0 as this 16-byte vector does. */
typedef uint64_t cqo_fp128_bits __attribute__((vector_size(16)));
long double __trunctfxf2(cqo_fp128_bits x) {
  uint64_t lo = x[0], hi = x[1];
  int e = (int)((hi >> 48) & 0x7fff);
  uint64_t m = (UINT64_C(1) << 63) | ((hi & UINT64_C(0xffffffffffff)) << 15) | (lo >> 49);
  uint64_t rest = lo & ((UINT64_C(1) << 49) - 1), half = UINT64_C(1) << 48;
  if (e == 0) /* zero (the expansion makes no subnormal fp128) */
    m = 0;
  else if (rest > half || (rest == half && (m & 1)))
    if (++m == 0) {
      m = UINT64_C(1) << 63;
      ++e;
    }
  unsigned char b[16] = {0};
  uint16_t se = (uint16_t)(e | (int)(hi >> 63) << 15);
  memcpy(b, &m, 8);
  memcpy(b + 8, &se, 2);
  long double r;
  memcpy(&r, b, 10);
  return r;
}
