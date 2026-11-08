/* rt_replay.h: clone replay (cq-kcn5i), the private interface between core.c, rt_bus.c, dispatch.c and rt_replay.c.
 * Not part of cqe.h. rt_replay.c has the design; this header only names who provides what. */
#ifndef RT_REPLAY_H_
#define RT_REPLAY_H_

#include <stddef.h>
#include <stdint.h>

/* Byte copy, compare and clear that never call the C library: the program under test may define memcpy, memcmp or
 * memset itself (190 links musl's memcmp), and the runtime's calls would bind to its lowered definition. */
__attribute__((no_builtin)) static inline void cqe__rp_cpy(void *d, const void *s, size_t n) {
  uint8_t *a = (uint8_t *)d;
  const uint8_t *b = (const uint8_t *)s;
  for (size_t i = 0; i < n; ++i)
    a[i] = b[i];
}
__attribute__((no_builtin)) static inline int cqe__rp_eq(const void *x, const void *y, size_t n) {
  const uint8_t *a = (const uint8_t *)x, *b = (const uint8_t *)y;
  for (size_t i = 0; i < n; ++i)
    if (a[i] != b[i])
      return 0;
  return 1;
}
__attribute__((no_builtin)) static inline void cqe__rp_zero(void *d, size_t n) {
  uint8_t *a = (uint8_t *)d;
  for (size_t i = 0; i < n; ++i)
    a[i] = 0;
}

/* A growable byte buffer (rt_replay.c). */
typedef struct {
  uint8_t *p;
  size_t n, cap;
} cqe_rp_buf;
void cqe__rp_put(cqe_rp_buf *b, const void *x, size_t n);

/* The rails one window made, encoded (core.c, cqe__rp_encode): rails base+1 .. base+n in creation order, their event
 * clocks relative to the window's start, their handles relative to its base or as argument indices. */
typedef struct {
  uint32_t n;      /* rails made */
  uint64_t ticks;  /* the event clock's advance */
  cqe_rp_buf blob; /* the rails */
  uint32_t *off;   /* n offsets into blob */
  /* derived for the exit event, never compared: per rail the offset of its value's hex in hexpool, UINT32_MAX for a
   * rail not live at the window's end */
  uint32_t *hexoff;
  char *hexpool;
} cqe_rp_rails;

/* ---- core.c ---- */
extern int cqe__rp_dirty;  /* the open window cannot be recorded */
extern int cqe__rp_window; /* a window is open (the hooks below log) */
void cqe__rp_watch(uint32_t base, const int32_t *args, int nargs, int on);
void cqe__rp_argkey(const int32_t *hs, int n, int absolute, cqe_rp_buf *out);
int cqe__rp_encode(uint32_t base, uint64_t c0, const int32_t *args, int nargs, cqe_rp_rails *out);
void cqe__rp_derive(cqe_rp_rails *rr);
int32_t cqe__rp_enc_handle(int32_t h, uint32_t base, const int32_t *args, int nargs, int *ok);
uint32_t cqe__rp_apply(const cqe_rp_rails *rr, const int32_t *args, int nargs);
int32_t cqe__rp_dec_handle(int32_t e, uint32_t base, const int32_t *args);
uint32_t cqe__rp_nrails(void);
uint64_t cqe__rp_clock(void);
unsigned long long cqe__rp_steps(void);
void cqe__rp_steps_add(unsigned long long d);
const uint32_t *cqe__rp_frees(size_t *n);
void cqe__rp_frees_apply(const uint32_t *rel, size_t n, uint32_t base);
long cqe__rp_shot_k(void);
int32_t cqe__rp_prealloc(void);
int cqe__rp_block_load(int32_t h, uint64_t *addr, int *fire);
uint64_t cqe__rp_materialized(void);
int cqe__rp_tamper(cqe_rp_rails *rr);

/* ---- rt_bus.c ---- */
int cqe__bus_load_of(int32_t h, uint64_t *addr, int *fire);
void cqe__bus_cell_state(uint64_t a, int *q, uint8_t *v, int *known);
uint8_t cqe__bus_host_byte(uint64_t a);
int cqe__bus_writable(uint64_t a);
void cqe__bus_cell_set(uint64_t a, int q, uint8_t v, int known, int host_changed, uint8_t hostv);

/* ---- rt_replay.c: the bus accesses of an open window ---- */
void cqe__rp_cell_read(uint64_t a, uint8_t v, int q, int known);
void cqe__rp_cell_wcheck(uint64_t a, int writable);
void cqe__rp_cell_wrote(uint64_t a, int host);

/* ---- dispatch.c ---- */
extern uint64_t cqe__ncalls;                /* runtime calls dispatched */
int cqe__rp_dispatch_idle(void);            /* no cq_invert region open or replaying */
void cqe__rp_stack_mark(int on);            /* the word stack's depth at a window's start; a pop below it is dirty */
int cqe__rp_stack_same(void);               /* the word stack is back at that depth */

#endif /* RT_REPLAY_H_ */
