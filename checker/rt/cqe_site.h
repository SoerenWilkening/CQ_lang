/* A stub's call site and the word entries (stubgen.py emits both; private to checker/rt). */
#ifndef CQE_SITE_H_
#define CQE_SITE_H_

#include <stddef.h>
#include <stdint.h>

struct site_res;
/* One per runtime symbol the program calls: { ptr sym, ptr sig, i32 nargs, i32 0, ptr null } in the stubs' module. */
typedef struct cqe_site_ {
  const char *sym, *sig;
  int32_t nargs;
  uint32_t kind;        /* 0 until the site is resolved; then CK_* and its fields (dispatch.c site_bind) */
  struct site_res *res; /* NULL until resolved */
} cqe_site;

/* A resolved site's kind (r7-fuse): which fused gate of core.c is the site's whole call when nothing is to be
 * recorded (no cq_invert region open) and its event is not written (a compact trace). CK_NONE: none; the site goes
 * through cqe_cw. Set only for a site whose fast gate (dispatch.c fast_pick) is that gate. */
enum { CK_NONE, CK_NOT, CK_XOR, CK_AND, CK_OR, CK_FREE, CK_ALLOC };
#define CK_KIND(k) ((k) & 0xffu)
#define CK_WI(k) ((uint16_t)((k) >> 8 & 0xfffu)) /* CK_ALLOC: the width token's index (core.c cqe__wi_of) */
#define CK_LITBITS(k) ((k) >> 20 & 0x7fu)        /* CK_ALLOC: the literal's bits, 1 .. 64 */

extern uint64_t cqe__ncalls; /* runtime calls dispatched (dispatch.c) */
extern size_t cqe__iv_nopen; /* cq_invert regions open (dispatch.c) */
uint64_t cqe_cw(cqe_site *s, const uint64_t *a);          /* the word entry of any site */
uint64_t cqe__cw_counted(cqe_site *s, const uint64_t *a); /* a counted call of a site with a fast gate: that gate */

#endif /* CQE_SITE_H_ */
