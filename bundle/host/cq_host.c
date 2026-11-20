/* cq_host.c: the injection-bundle host symbols (CR §1.3, BACKEND_ABI §0, §1.10, §1.14; rulings Q7). Classical host
 * C, one definition per process, linked AFTER the pass by run.py and driver/cqcc, never lowered: no gate here and
 * no call but the one that creates the bus.
 *
 *   int32_t __cq_mem(void)                     the bus handle; the first call makes it (cqrt_qram_alloc_i8(0))
 *   int64_t __cq_sig[65]                       one cell per signal number: the registered handler's address (rule 16)
 *   void *__cq_alloc(int64_t size, int64_t align)   size zeroed bytes at that alignment, never reused, size as an
 *                                              i64 in the 8 bytes before the result. Nothing frees it.
 *   void __cq_clone_register(fn, sig, clone, ctl, unc, ctl_unc), void *__cq_clone_resolve(fn, kind),
 *   int32_t __cq_clone_count(sig), void *__cq_clone_at(sig, i)    the process-wide clone table; sig by string
 *
 * The allocator hands out one mmap'd arena from a fixed hint address, so that a program's addresses depend only on
 * its __cq_alloc calls; a block never returns to it. When a chunk is exhausted another is mapped. It fails like
 * malloc: a size no mapping can hold returns null.
 *
 * __cq_host_snapshot / __cq_host_restore: called by the checker's shot worker only (checker/rt/core.c, weak there), so
 * that between two samples of one process the arena is what the setup left: the setup's blocks put back, the rest fresh
 * zero pages. The statics of this file are in __DATA, which the worker puts back itself. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

int32_t cqrt_qram_alloc_i8(int32_t n);

/* ---- the bus ---- */

int32_t __cq_mem(void) {
  static int32_t m;
  if (!m)
    m = cqrt_qram_alloc_i8(0);
  return m;
}

/* ---- signals ---- */

int64_t __cq_sig[65];

/* ---- the allocator ---- */

#define CHUNK ((uint64_t)1 << 33)
#define HINT ((uintptr_t)0x200000000000ULL)
#define MAX_CHUNKS 4096

typedef struct { char *base; uint64_t size; } chunk_t;
static chunk_t chunks[MAX_CHUNKS];
static int nchunks;
static char *top, *end;

static int chunk_new(uint64_t need) {
  uint64_t size = need > CHUNK ? need : CHUNK;
  if (nchunks == MAX_CHUNKS)
    return 0;
  void *hint = nchunks ? (void *)(chunks[nchunks - 1].base + chunks[nchunks - 1].size) : (void *)HINT;
  void *m = mmap(hint, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
  if (m == MAP_FAILED)
    return 0;
  chunks[nchunks++] = (chunk_t){m, size};
  top = m;
  end = top + size;
  return 1;
}

void *__cq_alloc(int64_t size, int64_t align) {
  uint64_t n = (uint64_t)size, a = align > 0 ? (uint64_t)align : 1;
  if (a & (a - 1)) {
    fprintf(stderr, "cq: __cq_alloc: alignment %lld is no power of two\n", (long long)align);
    abort();
  }
  if (n > UINT64_MAX - a - 8)
    return NULL;
  uint64_t need = n + a + 8;
  /* the header is 8 bytes below the block, whatever the alignment */
  if ((!top || (uint64_t)(end - top) < need) && !chunk_new(need))
    return NULL;
  char *p = (char *)(((uintptr_t)top + 8 + a - 1) & ~(uintptr_t)(a - 1));
  memcpy(p - 8, &size, 8);
  top = p + n;
  return p;
}

/* -- the checker's shots -- */

static int snap_chunks;
static char *snap_top;
static char *snap_copy;
static uint64_t snap_n;

void __cq_host_snapshot(void) {
  snap_chunks = nchunks;
  snap_top = top;
  snap_copy = NULL;
  snap_n = 0;
  for (int i = 0; i < nchunks; ++i)
    snap_n += i + 1 == nchunks ? (uint64_t)(top - chunks[i].base) : chunks[i].size;
  if (!snap_n)
    return;
  void *m = mmap(NULL, snap_n, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
  if (m == MAP_FAILED) {
    fprintf(stderr, "cq: __cq_alloc: cannot map the snapshot of the setup's blocks\n");
    abort();
  }
  snap_copy = m;
  uint64_t off = 0;
  for (int i = 0; i < nchunks; ++i) {
    uint64_t k = i + 1 == nchunks ? (uint64_t)(top - chunks[i].base) : chunks[i].size;
    memcpy(snap_copy + off, chunks[i].base, k);
    off += k;
  }
}

/* The sample's chunks go, the rest of the setup's last chunk becomes fresh zero pages, the setup's blocks come back.
 * Runs before __DATA is put back: nchunks, top and end are the sample's, and __DATA then restores the setup's. */
void __cq_host_restore(void) {
  uint64_t pg = (uint64_t)getpagesize();
  for (int i = snap_chunks; i < nchunks; ++i)
    munmap(chunks[i].base, chunks[i].size);
  if (snap_chunks == 0) {
    return;
  }
  chunk_t *last = &chunks[snap_chunks - 1];
  /* a chunk the sample mapped beyond the setup's leaves the setup's last chunk full: top is then not in it */
  char *high = snap_chunks == nchunks ? top : last->base + last->size;
  char *from = (char *)(((uintptr_t)snap_top + pg - 1) & ~(uintptr_t)(pg - 1));
  if (high > from && mmap(from, (size_t)(((uintptr_t)high - (uintptr_t)from + pg - 1) & ~(uintptr_t)(pg - 1)),
                          PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON | MAP_FIXED, -1, 0) == MAP_FAILED) {
    fprintf(stderr, "cq: __cq_alloc: cannot map fresh pages at the end of a sample\n");
    abort();
  }
  if (from > snap_top)
    memset(snap_top, 0, (size_t)(from - snap_top));
  uint64_t off = 0;
  for (int i = 0; i < snap_chunks; ++i) {
    uint64_t k = i + 1 == snap_chunks ? (uint64_t)(snap_top - chunks[i].base) : chunks[i].size;
    memcpy(chunks[i].base, snap_copy + off, k);
    off += k;
  }
}

/* ---- the clone table ---- */

typedef struct {
  const void *fn;
  const char *sig;
  void *k[4];
} row_t;
static row_t *rows;
static size_t nrows, caprows;

void __cq_clone_register(const void *fn, const char *sig, void *clone, void *ctl, void *unc, void *ctl_unc) {
  void *k[4] = {clone, ctl, unc, ctl_unc};
  for (size_t i = 0; i < nrows; ++i)
    if (rows[i].fn == fn) {
      /* Two names of one host function register a row each: macOS libm's ldexp is scalbn. Both rows lower that one
       * function, so the first stands; only a different signature for one address is a conflict. */
      if (strcmp(rows[i].sig, sig) != 0) {
        fprintf(stderr, "cq: __cq_clone_register: %p registered twice with different rows\n", fn);
        abort();
      }
      return;
    }
  if (nrows == caprows) {
    caprows = caprows ? 2 * caprows : 16;
    rows = realloc(rows, caprows * sizeof *rows);
    if (!rows)
      abort();
  }
  row_t r = {fn, sig, {clone, ctl, unc, ctl_unc}};
  rows[nrows++] = r;
}

void *__cq_clone_resolve(const void *fn, int32_t kind) {
  if (kind < 0 || kind > 3) {
    fprintf(stderr, "cq: __cq_clone_resolve: kind %d is none of 0 (forward), 1 (_ctl), 2 (_unc), 3 (_ctl_unc)\n", (int)kind);
    abort();
  }
  for (size_t i = 0; i < nrows; ++i)
    if (rows[i].fn == fn)
      return rows[i].k[kind];
  return NULL;
}

int32_t __cq_clone_count(const char *sig) {
  int32_t n = 0;
  for (size_t i = 0; i < nrows; ++i)
    n += strcmp(rows[i].sig, sig) == 0;
  return n;
}

void *__cq_clone_at(const char *sig, int32_t idx) {
  int32_t n = 0;
  for (size_t i = 0; i < nrows; ++i)
    if (strcmp(rows[i].sig, sig) == 0 && n++ == idx)
      return (void *)rows[i].fn;
  fprintf(stderr, "cq: __cq_clone_at: index %d past the rows of '%s'\n", (int)idx, sig);
  abort();
}
