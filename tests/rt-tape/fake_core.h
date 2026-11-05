/* Test-private helpers of fake_core.c (tests/rt-tape only). */
#ifndef FAKE_CORE_H_
#define FAKE_CORE_H_
#include <stdint.h>
#include "cqe.h"

extern int fake_violations;
cqe_val fake_i(uint32_t bits, uint64_t lo, uint64_t hi);   /* integer value, two low words */
cqe_val fake_f(uint32_t bits, uint64_t lo, uint64_t hi);   /* fp bit pattern */
cqe_val fake_h(int32_t h);                                 /* an i32 handle argument */
cqe_val fake_p(const void *p);                             /* a ptr argument */
int32_t fake_rail(const char *w, cqe_val v);               /* a classical-valued rail holding v */
int32_t fake_qrail(const char *w, cqe_val v);              /* a rail that is not classical-valued */
/* Plays the C1 dispatcher for a cqrt_ symbol: tname from the name, roles, M1 out, return-code checks. */
int32_t fake_call(const char *sym, int nargs, ...);
void fake_free(int32_t h);                                 /* cqrt_free with the known-basis rule */
void fake_set(int32_t h, cqe_val v);                       /* overwrite a rail (a mutation) */
/* The return code of the handler under `key` called with tname.op = op and no arguments. */
int fake_rc(const char *key, const char *op);
#endif
