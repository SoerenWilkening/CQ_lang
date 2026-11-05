/* tests/rt-bus: one scenario per process (argv[1]); test_rt_bus.py reads the trace. Calls go through the real
 * dispatcher, the way a generated stub calls. Values are checked here with CHECK; roles, violations and the
 * cells event by the Python side. */
#include <setjmp.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#include "cqe.h"

void cqe_dispatch(const char *sym, const char *sig, int32_t nargs, void **argv, void *ret);
int32_t __cq_mem(void);
void *__cq_alloc(int64_t size, int64_t align);
extern int64_t __cq_sig[65];
void __cq_clone_register(const void *fn, const char *sig, void *clone, void *ctl, void *unc, void *ctl_unc);
void *__cq_clone_resolve(const void *fn, int32_t kind);
int32_t __cq_clone_count(const char *sig);
void *__cq_clone_at(const char *sig, int32_t i);
void __cqe_out_mem(const char *name, uint64_t addr, uint64_t bytes);
sigjmp_buf *cqe__shot_jb(void);
void cqe__shot_resume(void);
int cqe__shot_enter(int idx);
void cqe__shot_end(void);

static int failed;
#define CHECK(c)                                                 \
  do {                                                           \
    if (!(c)) {                                                  \
      fprintf(stderr, "CHECK %s:%d: %s\n", __FILE__, __LINE__, #c); \
      failed = 1;                                                \
    }                                                            \
  } while (0)

/* call("cqrt_x", "ret|t0,t1", a0, a1, ...): every argument a uint64_t, stored little-endian; returns the low 64 bits */
static uint64_t callv(const char *sym, const char *sig, int n, ...) {
  uint64_t vals[8][4], ret[4] = {0};
  void *argv[8];
  va_list ap;
  va_start(ap, n);
  for (int i = 0; i < n; ++i) {
    memset(vals[i], 0, sizeof vals[i]);
    vals[i][0] = va_arg(ap, uint64_t);
    argv[i] = vals[i];
  }
  va_end(ap);
  cqe_dispatch(sym, sig, n, argv, ret);
  return ret[0];
}
#define U(x) ((uint64_t)(x))
#define A(x) ((uint64_t)(uintptr_t)(x))
#define C1(s, sig, a) callv(s, sig, 1, U(a))
#define C2(s, sig, a, b) callv(s, sig, 2, U(a), U(b))
#define C3(s, sig, a, b, c) callv(s, sig, 3, U(a), U(b), U(c))
#define C4(s, sig, a, b, c, d) callv(s, sig, 4, U(a), U(b), U(c), U(d))

static int32_t seed32(uint32_t v) { return (int32_t)C1("cqrt_alloc_i32", "i32|i32", v); }
static int32_t seed1(int v) { return (int32_t)C1("cqrt_alloc_i1", "i32|i1", v); }
static int32_t seed64(uint64_t v) { return (int32_t)C1("cqrt_alloc_i64", "i32|i64", v); }
static uint64_t val(int32_t h) { return cqe_rail(h)->w[0]; }
static void ry32(int32_t h) {
  double t = 0.5;
  uint64_t b;
  memcpy(&b, &t, 8);
  C2("cqrt_ry_i32", "void|i32,double", h, b);
}
static void ry1(int32_t h) {
  double t = 0.5;
  uint64_t b;
  memcpy(&b, &t, 8);
  C2("cqrt_ry_i1", "void|i32,double", h, b);
}
static void fr(int32_t h) { C1("cqrt_free", "void|i32", h); }
#define LOADHL32(m, p) ((int32_t)C2("cqrt_qram_load_i32_hl", "i32|i32,i64", m, A(p)))
#define UNCHL32(h, m, p) C3("cqrt_qram_load_i32_hl_unc", "void|i32,i32,i64", h, m, A(p))
#define STOREHL32(m, p, v) C3("cqrt_qram_store_i32_hl", "void|i32,i64,i32", m, A(p), v)
#define SWAPHL32(m, p, h) C3("cqrt_qram_swap_i32_hl", "void|i32,i64,i32", m, A(p), h)

static uint32_t g = 0x11223344, g2 = 0x55667788;

/* every op on HOST cells, classical: _hl and rail forms; the store writes host memory, the cells stay HOST */
static void host_ops(void) {
  int32_t m = __cq_mem();
  CHECK(m == __cq_mem());
  int32_t h = LOADHL32(m, &g);
  CHECK(val(h) == 0x11223344);
  UNCHL32(h, m, &g);
  CHECK(val(h) == 0);
  fr(h);
  int32_t a = seed64(A(&g));
  h = (int32_t)C2("cqrt_qram_load_i32", "i32|i32,i32", m, a);
  CHECK(val(h) == 0x11223344);
  C3("cqrt_qram_load_i32_unc", "void|i32,i32,i32", h, m, a);
  fr(h);
  int32_t v = seed32(0xAABBCCDD);
  STOREHL32(m, &g, v); /* the slot: displaced 0x11223344, kept */
  CHECK(g == 0xAABBCCDD);
  fr(v); /* a seed the caller minted may be freed: it is classical-valued */
  v = seed32(5);
  C3("cqrt_qram_store_i32", "void|i32,i32,i32", m, a, v); /* the plain form; the slot holds 0xAABBCCDD */
  CHECK(g == 5);
  int32_t s = seed32(9);
  SWAPHL32(m, &g, s);
  CHECK(val(s) == 5 && g == 9);
  C3("cqrt_qram_swap_i32", "void|i32,i32,i32", m, a, s);
  CHECK(val(s) == 9 && g == 5);
  fr(s);
  fr(a);
}

/* every op on QUANTUM cells: a rotated value makes the cells QUANTUM, the host byte stays; later classical events bring
 * the cells back to HOST */
static void quantum_ops(void) {
  int32_t m = __cq_mem();
  int32_t q = seed32(7);
  ry32(q);
  STOREHL32(m, &g, q);
  CHECK(g == 0x11223344); /* no host write */
  int32_t h = LOADHL32(m, &g);
  CHECK(val(h) == 7);
  UNCHL32(h, m, &g);
  CHECK(val(h) == 0);
  fr(h);
  __cqe_out_mem("g_quantum", A(&g), 4);
  /* swap on a QUANTUM cell: h gets the content; the cells' classical 0 goes to host memory */
  h = seed32(0);
  SWAPHL32(m, &g, h);
  CHECK(val(h) == 7 && g == 0);
  ry32(h); /* in the middle of the in-place form */
  SWAPHL32(m, &g, h);
  CHECK(val(h) == 0 && g == 0); /* QUANTUM again, host byte stays at 0 */
  fr(h);                        /* the rail the cells' 0 went to: legal */
  /* a classical store over QUANTUM cells: HOST again; the slot holds the displaced quantum value, not known */
  int32_t v = seed32(9);
  STOREHL32(m, &g, v);
  CHECK(g == 9);
  fr(v);
  /* g2 stays QUANTUM at exit, the cells event lists it */
  STOREHL32(m, &g2, q);
}

/* _controlled: c = 0 touches nothing (no host byte, no cell, the slot and the load copy |0>); c = 1 as the plain form */
static void controlled(void) {
  int32_t m = __cq_mem();
  int32_t c0 = seed1(0), c1 = seed1(1);
  int32_t v = seed32(0x77);
  int32_t h = (int32_t)C3("cqrt_qram_load_i32_hl_controlled", "i32|i32,i32,i64", c0, m, A(&g));
  CHECK(val(h) == 0);
  C4("cqrt_qram_load_i32_hl_controlled_unc", "void|i32,i32,i32,i64", h, c0, m, A(&g));
  fr(h);
  C4("cqrt_qram_store_i32_hl_controlled", "void|i32,i32,i64,i32", c0, m, A(&g), v);
  CHECK(g == 0x11223344);
  int32_t s = seed32(3);
  C4("cqrt_qram_swap_i32_hl_controlled", "void|i32,i32,i64,i32", c0, m, A(&g), s);
  CHECK(g == 0x11223344 && val(s) == 3);
  /* at an unreadable, unwritable address too: nothing is touched */
  h = (int32_t)C3("cqrt_qram_load_i32_hl_controlled", "i32|i32,i32,i64", c0, m, 0x10);
  CHECK(val(h) == 0);
  fr(h);
  C4("cqrt_qram_store_i32_hl_controlled", "void|i32,i32,i64,i32", c0, m, 0x10, v);
  /* c = 1 and classical-valued: as the plain form, host memory written */
  h = (int32_t)C3("cqrt_qram_load_i32_hl_controlled", "i32|i32,i32,i64", c1, m, A(&g));
  CHECK(val(h) == 0x11223344);
  C4("cqrt_qram_load_i32_hl_controlled_unc", "void|i32,i32,i32,i64", h, c1, m, A(&g));
  fr(h);
  C4("cqrt_qram_store_i32_hl_controlled", "void|i32,i32,i64,i32", c1, m, A(&g), v);
  CHECK(g == 0x77);
  C4("cqrt_qram_swap_i32_hl_controlled", "void|i32,i32,i64,i32", c1, m, A(&g), s);
  CHECK(g == 3 && val(s) == 0x77);
  fr(s);
  fr(v);
  fr(c0);
  fr(c1);
}

/* A control that is not classical-valued and reads 0 here: the cells keep their content and go QUANTUM (the branch where
 * it reads 1 reaches them); no host write. Under a value 1: QUANTUM with the content written. The in-place form under
 * it ends with the rail at 0, freed. */
static void controlled_quantum(void) {
  int32_t m = __cq_mem();
  int32_t c0 = seed1(0);
  ry1(c0); /* no schedule: stays 0, not classical-valued */
  int32_t v = seed32(0x77);
  C4("cqrt_qram_store_i32_hl_controlled", "void|i32,i32,i64,i32", c0, m, A(&g), v);
  CHECK(g == 0x11223344);
  int32_t h = LOADHL32(m, &g);
  CHECK(val(h) == 0x11223344); /* QUANTUM, content kept */
  UNCHL32(h, m, &g);
  fr(h);
  /* the controlled in-place form on g2 */
  h = seed32(0);
  C4("cqrt_qram_swap_i32_hl_controlled", "void|i32,i32,i64,i32", c0, m, A(&g2), h);
  CHECK(val(h) == 0);
  C4("cqrt_qram_swap_i32_hl_controlled", "void|i32,i32,i64,i32", c0, m, A(&g2), h);
  CHECK(val(h) == 0);
  fr(h);
}

/* No fault: an unreadable HOST cell reads 0, by _hl and by rail, per cell, with the wrap mod 2^64 */
static void unreadable(void) {
  int32_t m = __cq_mem();
  int32_t h = (int32_t)C2("cqrt_qram_load_i32_hl", "i32|i32,i64", m, 0x10);
  CHECK(val(h) == 0);
  C3("cqrt_qram_load_i32_hl_unc", "void|i32,i32,i64", h, m, 0x10);
  fr(h);
  long pg = getpagesize();
  char *p = mmap(NULL, (size_t)pg * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
  CHECK(p != MAP_FAILED);
  mprotect(p + pg, (size_t)pg, PROT_NONE);
  memset(p + pg - 2, 0xAB, 2);
  int32_t a = seed64(A(p + pg));
  h = (int32_t)C2("cqrt_qram_load_i32", "i32|i32,i32", m, a);
  CHECK(val(h) == 0);
  fr(h);
  /* an access straddling into the unreadable page: decided per cell */
  h = LOADHL32(m, p + pg - 2);
  CHECK(val(h) == 0xABAB);
  fr(h);
  /* wrap: cells ...FE, ...FF, 0, 1 */
  h = (int32_t)C2("cqrt_qram_load_i32_hl", "i32|i32,i64", m, 0xFFFFFFFFFFFFFFFEULL);
  CHECK(val(h) == 0);
  fr(h);
  int32_t v = seed32(0x04030201);
  C3("cqrt_qram_store_i32_hl", "void|i32,i64,i32", m, 0xFFFFFFFFFFFFFFFEULL, v);
  h = (int32_t)C2("cqrt_qram_load_i8_hl", "i32|i32,i64", m, 1);
  CHECK(val(h) == 4);
  fr(h);
  fr(v);
}

/* A classical store to an address that is not writable makes the cell QUANTUM and writes no host byte; the displaced
 * content is the host byte where readable, 0 where not. The cell stays classical-valued (a load's free needs no _unc). */
static void unwritable(void) {
  int32_t m = __cq_mem();
  long pg = getpagesize();
  unsigned char *p = mmap(NULL, (size_t)pg, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
  p[0] = 0x5A;
  mprotect(p, (size_t)pg, PROT_READ);
  int32_t v = (int32_t)C1("cqrt_alloc_i8", "i32|i8", 0x66);
  C3("cqrt_qram_store_i8_hl", "void|i32,i64,i32", m, A(p), v);
  CHECK(p[0] == 0x5A);
  int32_t h = (int32_t)C2("cqrt_qram_load_i8_hl", "i32|i32,i64", m, A(p));
  CHECK(val(h) == 0x66);
  fr(h); /* classical-valued without an _unc */
  /* unmapped: displaced 0, QUANTUM */
  C3("cqrt_qram_store_i8_hl", "void|i32,i64,i32", m, 0x20, v);
  h = (int32_t)C2("cqrt_qram_load_i8_hl", "i32|i32,i64", m, 0x20);
  CHECK(val(h) == 0x66);
  fr(h);
  fr(v);
}

/* ABI "Classical-valued _unc": host code changed the cells between: h ends non-zero, the free is legal */
static void classical_unc(void) {
  int32_t m = __cq_mem();
  int32_t h = LOADHL32(m, &g);
  g += 1;
  UNCHL32(h, m, &g);
  CHECK(val(h) == 1);
  fr(h);
}

/* A quantum copy overtaken by a store: _unc leaves non-zero. Not freed: role overtaken. Freed: dirty_free (a2). */
static void overtaken(void) {
  int32_t m = __cq_mem();
  int32_t q = seed32(7), r = seed32(8);
  ry32(q);
  ry32(r);
  STOREHL32(m, &g, q);
  int32_t h = LOADHL32(m, &g);
  STOREHL32(m, &g, r);
  UNCHL32(h, m, &g);
  CHECK(val(h) == 15);
}
static void overtaken_freed(void) {
  int32_t m = __cq_mem();
  int32_t q = seed32(7), r = seed32(8);
  ry32(q);
  ry32(r);
  STOREHL32(m, &g, q);
  int32_t h = LOADHL32(m, &g);
  STOREHL32(m, &g, r);
  UNCHL32(h, m, &g);
  fr(h); /* non-zero and not classical-valued */
}

/* Exit roles: tape_slot per store, store_kept for a template result that is a store's value and for its control rail,
 * frozen for a rotated value */
static void roles(void) {
  int32_t m = __cq_mem();
  int32_t q = seed32(7);
  ry32(q);
  int32_t t = (int32_t)C2("cq_template_add_i32_hl", "i32|i32,i32", q, 1);
  CHECK(val(t) == 8);
  STOREHL32(m, &g, t);
  int32_t c = (int32_t)C2("cq_template_icmp_eq_i32_hl", "i32|i32,i32", q, 7);
  int32_t v2 = seed32(1);
  C4("cqrt_qram_store_i32_hl_controlled", "void|i32,i32,i64,i32", c, m, A(&g2), v2);
  CHECK(g2 == 0x55667788);
}

static void v_rotated_copy_unc(void) {
  int32_t m = __cq_mem();
  int32_t h = LOADHL32(m, &g);
  ry32(h);
  UNCHL32(h, m, &g);
}
static void v_measured_copy_unc(void) {
  int32_t m = __cq_mem();
  int32_t h = LOADHL32(m, &g);
  C1("cqrt_measure_i32", "i32|i32", h);
  UNCHL32(h, m, &g);
}
static void v_unc_address(void) {
  int32_t m = __cq_mem();
  int32_t h = LOADHL32(m, &g);
  UNCHL32(h, m, &g2);
}
static void v_dirty_load_free(void) {
  int32_t m = __cq_mem();
  int32_t q = seed32(7);
  ry32(q);
  STOREHL32(m, &g, q);
  fr(LOADHL32(m, &g)); /* a quantum copy with no _unc */
}
static void v_second_bus(void) {
  __cq_mem();
  C1("cqrt_qram_alloc_i8", "i32|i32", 0);
}
static void v_bad_bus(void) {
  __cq_mem();
  C2("cqrt_qram_load_i32_hl", "i32|i32,i64", 7, A(&g));
}
static void v_no_bus(void) { C2("cqrt_qram_load_i32_hl", "i32|i32,i64", 0x51000000, A(&g)); }
static void v_sized_bus(void) { C1("cqrt_qram_alloc_i8", "i32|i32", 4); }
static void v_other_width_bus(void) { C1("cqrt_qram_alloc_i32", "i32|i32", 0); }
static void v_addr_width(void) {
  int32_t m = __cq_mem(), a = seed32(0);
  C2("cqrt_qram_load_i32", "i32|i32,i32", m, a);
}
static void v_value_width(void) {
  int32_t m = __cq_mem(), v = seed32(0);
  C3("cqrt_qram_store_i8_hl", "void|i32,i64,i32", m, A(&g), v);
}
static void v_store_unc(void) {
  int32_t m = __cq_mem(), v = seed32(0);
  C3("cqrt_qram_store_i32_hl_unc", "void|i32,i64,i32", m, A(&g), v);
}
static void v_swap_alias(void) {
  int32_t m = __cq_mem(), a = seed64(A(&g));
  C3("cqrt_qram_swap_i64", "void|i32,i32,i32", m, a, a);
}
static void v_retired(void) {
  C1("cqrt_qram_free", "void|i32", 1);
  C2("cqrt_qram_realloc_i32", "i32|i32,i32", 1, 2);
  C1("cqrt_qram_size", "i32|i32", 1);
  C2("cq_template_qrom_load_i32", "i32|i32,i32", 1, 2);
  C2("cqrt_clone_resolve", "ptr|ptr,i32", 1, 0);
}

/* widths: S cells, little-endian; a swap leaves the high bits of a partial cell; a store zero-extends; f80 10 cells */
static unsigned char cellbuf[32];
static void widths(void) {
  int32_t m = __cq_mem();
  /* i1 store: zero-extended; slot i8 */
  cellbuf[0] = 0xF0;
  int32_t b = seed1(1);
  C3("cqrt_qram_store_i1_hl", "void|i32,i64,i32", m, A(cellbuf), b);
  CHECK(cellbuf[0] == 1);
  fr(b);
  /* i1 load: the low bit */
  cellbuf[0] = 0xF1;
  int32_t h = (int32_t)C2("cqrt_qram_load_i1_hl", "i32|i32,i64", m, A(cellbuf));
  CHECK(val(h) == 1);
  fr(h);
  /* i1 swap: high bits stay */
  cellbuf[0] = 0xF0;
  h = seed1(1);
  C3("cqrt_qram_swap_i1_hl", "void|i32,i64,i32", m, A(cellbuf), h);
  CHECK(cellbuf[0] == 0xF1 && val(h) == 0);
  fr(h);
  /* i7 */
  cellbuf[1] = 0xFF;
  h = (int32_t)C1("cqrt_alloc_i7", "i32|i7", 0x05);
  C3("cqrt_qram_swap_i7_hl", "void|i32,i64,i32", m, A(cellbuf + 1), h);
  CHECK(cellbuf[1] == 0x85 && val(h) == 0x7F);
  fr(h);
  /* i16 little-endian */
  cellbuf[2] = 0x34;
  cellbuf[3] = 0x12;
  h = (int32_t)C2("cqrt_qram_load_i16_hl", "i32|i32,i64", m, A(cellbuf + 2));
  CHECK(val(h) == 0x1234);
  fr(h);
  /* i64 */
  memset(cellbuf, 0, 32);
  uint64_t x = 0x0102030405060708ULL;
  memcpy(cellbuf, &x, 8);
  h = (int32_t)C2("cqrt_qram_load_i64_hl", "i32|i32,i64", m, A(cellbuf));
  CHECK(val(h) == x);
  fr(h);
  /* f80: 10 cells, bytes 10.. not touched */
  memset(cellbuf, 0xEE, 32);
  uint64_t f[2] = {0x8000000000000000ULL, 0x3FFF};
  void *fa = f;
  int32_t fv, ret;
  { void *argv[1] = {fa}; cqe_dispatch("cqrt_alloc_f80", "i32|x86_fp80", 1, argv, &fv); }
  C3("cqrt_qram_store_f80_hl", "void|i32,i64,i32", m, A(cellbuf), fv);
  CHECK(cellbuf[9] == 0x3F && cellbuf[8] == 0xFF && cellbuf[10] == 0xEE);
  ret = (int32_t)C2("cqrt_qram_load_f80_hl", "i32|i32,i64", m, A(cellbuf));
  CHECK(cqe_rail(ret)->w[0] == f[0] && cqe_rail(ret)->w[1] == f[1]);
  fr(ret);
  fr(fv);
  /* i100: 13 cells, zero-extended; the top cell's high 4 bits read 0 */
  memset(cellbuf, 0xEE, 32);
  uint64_t w[2] = {~0ULL, (1ULL << 36) - 1};
  void *wa = w;
  int32_t wv;
  { void *argv[1] = {wa}; cqe_dispatch("cqrt_alloc_i100", "i32|i100", 1, argv, &wv); }
  C3("cqrt_qram_store_i100_hl", "void|i32,i64,i32", m, A(cellbuf), wv);
  CHECK(cellbuf[12] == 0x0F && cellbuf[11] == 0xFF && cellbuf[13] == 0xEE);
  fr(wv);
  /* i128 */
  memset(cellbuf, 0x11, 32);
  int32_t i = (int32_t)C2("cqrt_qram_load_i128_hl", "i32|i32,i64", m, A(cellbuf));
  CHECK(cqe_rail(i)->w[0] == 0x1111111111111111ULL && cqe_rail(i)->w[1] == 0x1111111111111111ULL);
  fr(i);
  /* bf16, f32 */
  memset(cellbuf, 0, 32);
  cellbuf[1] = 0x3F;
  i = (int32_t)C2("cqrt_qram_load_bf16_hl", "i32|i32,i64", m, A(cellbuf));
  CHECK(val(i) == 0x3F00);
  fr(i);
  i = (int32_t)C2("cqrt_qram_load_f32_hl", "i32|i32,i64", m, A(cellbuf));
  CHECK(val(i) == 0x3F00);
  fr(i);
}

/* __cq_alloc: the size header, the alignment, zeroed, never reused */
static void alloc(void) {
  char *a = __cq_alloc(16, 16), *b = __cq_alloc(3, 1), *c = __cq_alloc(0, 8), *d = __cq_alloc(64, 4096);
  CHECK(((uintptr_t)a & 15) == 0 && ((uintptr_t)c & 7) == 0 && ((uintptr_t)d & 4095) == 0);
  int64_t s;
  memcpy(&s, a - 8, 8);
  CHECK(s == 16);
  memcpy(&s, b - 8, 8);
  CHECK(s == 3);
  memcpy(&s, c - 8, 8);
  CHECK(s == 0);
  memcpy(&s, d - 8, 8);
  CHECK(s == 64);
  CHECK(a + 16 <= b - 8 && b + 3 <= c - 8 && c <= d - 8);
  for (int i = 0; i < 16; ++i)
    CHECK(a[i] == 0);
  char *e = __cq_alloc(16, 16);
  CHECK(e > d);
  /* the header is HOST cells, read through the bus (rule 16 realloc) */
  int32_t m = __cq_mem();
  int32_t h = (int32_t)C2("cqrt_qram_load_i64_hl", "i32|i32,i64", m, A(e - 8));
  CHECK(val(h) == 16);
  fr(h);
  /* a huge size fails like malloc */
  CHECK(__cq_alloc(INT64_MAX, 1) == NULL);
  /* a block larger than a chunk */
  char *big = __cq_alloc((int64_t)1 << 34, 16);
  CHECK(big && big > e);
  memcpy(&s, big - 8, 8);
  CHECK(s == (int64_t)1 << 34);
  CHECK(__cq_sig[0] == 0 && __cq_sig[64] == 0);
}

static int fa_, fb_, fc_;
static void clones(void) {
  int c1[4], c2[4];
  __cq_clone_register(&fa_, "i32 (i32)", &c1[0], &c1[1], &c1[2], &c1[3]);
  __cq_clone_register(&fb_, "void (ptr, i64)", &c2[0], &c2[1], &c2[2], &c2[3]);
  __cq_clone_register(&fc_, "i32 (i32)", &c2[0], &c2[1], &c2[2], &c2[3]);
  __cq_clone_register(&fa_, "i32 (i32)", &c1[0], &c1[1], &c1[2], &c1[3]); /* the same row again: nothing */
  CHECK(__cq_clone_resolve(&fa_, 0) == &c1[0]);
  CHECK(__cq_clone_resolve(&fa_, 1) == &c1[1]);
  CHECK(__cq_clone_resolve(&fa_, 2) == &c1[2]);
  CHECK(__cq_clone_resolve(&fa_, 3) == &c1[3]);
  CHECK(__cq_clone_resolve(&failed, 0) == NULL);
  char sig[32];
  snprintf(sig, sizeof sig, "i32 (%s)", "i32"); /* compared by string, not by pointer */
  CHECK(__cq_clone_count(sig) == 2);
  CHECK(__cq_clone_count("void (ptr, i64)") == 1);
  CHECK(__cq_clone_count("void ()") == 0);
  CHECK(__cq_clone_at(sig, 0) == &fa_);
  CHECK(__cq_clone_at(sig, 1) == &fc_);
  CHECK(__cq_clone_at("void (ptr, i64)", 0) == &fb_);
}
static void clone_bad_kind(void) { __cq_clone_resolve(&fa_, 4); }

/* Two samples of one process start from the same state: bus handle, QUANTUM cells, __cq_alloc addresses and contents (the
 * setup's blocks put back, the rest zero again), host writes through the bus */
static void shots(void) {
  int32_t m0 = __cq_mem();
  char *setup = __cq_alloc(8, 8);
  memset(setup, 0x42, 8);
  uint32_t *other = (uint32_t *)__cq_alloc(4, 4);
  *other = 0;
  for (int i = 0; i < 3; ++i) {
    if (sigsetjmp(*cqe__shot_jb(), 1) != 0) {
      cqe__shot_resume();
    } else if (cqe__shot_enter(i)) {
      int32_t m = __cq_mem();
      CHECK(m == m0);
      char *x = __cq_alloc(32, 16);
      __cqe_out_mem("fresh", A(x), 4);
      CHECK(*(uint32_t *)x == 0);
      *(uint32_t *)x = 0xDEAD0000u + (uint32_t)i;
      __cqe_out_mem("setup", A(setup), 8);
      __cqe_out_mem("other", A(other), 4);
      /* a host write of a setup block, a classical bus store, a QUANTUM cell */
      memset(setup, 0x43, 8);
      int32_t v = seed32(5 + (uint32_t)i);
      STOREHL32(m, other, v);
      int32_t q = seed32(7);
      ry32(q);
      STOREHL32(m, x + 16, q);
      char addr[32];
      snprintf(addr, sizeof addr, "x%d", (int)(A(x) & 0xffff));
      __cqe_out_mem(addr, A(x + 16), 4);
      __cqe_out_mem("g", A(&g), 4);
      STOREHL32(m, &g, v);
      cqe__shot_end();
    }
  }
}

/* a cq_invert region: a swap and a load are recorded and reversed; a store flushes what was recorded before it, and is
 * performed at its call, its slot kept */
static void invert(void) {
  int32_t m = __cq_mem();
  int32_t h = seed32(9);
  callv("cqrt_invert_begin", "void|", 0);
  SWAPHL32(m, &g, h);
  CHECK(g == 0x11223344); /* recorded, not applied */
  callv("cqrt_invert_end", "void|", 0);
  CHECK(g == 9 && val(h) == 0x11223344);
  /* the store flushes: the swap before it applies at once */
  int32_t v = seed32(0x100);
  callv("cqrt_invert_begin", "void|", 0);
  SWAPHL32(m, &g, h); /* g = 0x11223344, h = 9 */
  STOREHL32(m, &g2, v);
  CHECK(g == 0x11223344 && val(h) == 9 && g2 == 0x100);
  callv("cqrt_invert_end", "void|", 0);
  fr(v);
  /* a load and its _unc in a region: they reverse into each other */
  callv("cqrt_invert_begin", "void|", 0);
  int32_t l = LOADHL32(m, &g);
  UNCHL32(l, m, &g);
  fr(l);
  callv("cqrt_invert_end", "void|", 0);
  fr(h);
}

/* An INPUT effect entry under a control that is not classical-valued: its bytes are bus stores (rt_tape.h, qstore):
 * the cells QUANTUM, one kept slot per cell, no host write; where the control reads 0 the cells keep their value. */
static unsigned char inbuf[8] = {0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7};
static void effect_qstore(int cv) {
  __cq_mem();
  int32_t c = seed1(cv);
  ry1(c);
  int32_t t = (int32_t)callv("cqrt_tape_alloc", "i32|", 0);
  C2("cqrt_tape_write_i64_lit", "void|i32,i64", t, A(inbuf));
  C2("cqrt_tape_write_i32_lit", "void|i32,i32", t, 4);
  C2("cqrt_tape_write_i64_lit", "void|i32,i64", t, 0x1000);
  C3("cqrt_tape_effect_i64_controlled", "i32|i32,i32,ptr", c, t, A("fgets"));
  CHECK(inbuf[0] == 0xA0 && inbuf[1] == 0xA1); /* no host write */
  __cqe_out_mem("inbuf", A(inbuf), 4);
}
static void effect_qstore_1(void) { effect_qstore(1); }
static void effect_qstore_0(void) { effect_qstore(0); }

int main(int argc, char **argv) {
#define S(n) {#n, n}
  static const struct { const char *name; void (*fn)(void); } sc[] = {
      S(host_ops), S(quantum_ops), S(controlled), S(controlled_quantum), S(unreadable), S(unwritable), S(classical_unc), S(overtaken),
      S(overtaken_freed), S(roles), S(v_rotated_copy_unc), S(v_measured_copy_unc), S(v_unc_address), S(v_dirty_load_free),
      S(v_second_bus), S(v_bad_bus), S(v_no_bus), S(v_sized_bus), S(v_other_width_bus), S(v_addr_width), S(v_value_width), S(v_store_unc),
      S(v_swap_alias), S(v_retired), S(widths), S(alloc), S(clones), S(clone_bad_kind), S(shots), S(invert),
      S(effect_qstore_1), S(effect_qstore_0),
  };
  if (argc != 2)
    return 2;
  for (size_t i = 0; i < sizeof sc / sizeof *sc; ++i)
    if (!strcmp(argv[1], sc[i].name)) {
      sc[i].fn();
      return failed;
    }
  fprintf(stderr, "no scenario %s\n", argv[1]);
  return 2;
}
