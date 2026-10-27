/* Test-only family for tests/chk-core (cq-f69, never in checker/rt): exercises M1's handler order on
 * op "mul" through the real dispatcher. Registration order: mf_a, mf_b, mf_a again (M1: a no-op),
 * mf_c.
 *   i8   mf_a computes the product; nothing after it may run (mf_b and mf_c would give other values).
 *   i32  mf_a scribbles on out->w and declines; mf_b ORs the product into out->w, so its result is
 *        right only if the dispatcher zeroed out->w again (M1).
 *   i16  mf_a declines; mf_b calls cqe_fail and returns -1; mf_c, which would compute, must not run.
 *   i64  every handler declines, so no_family. mf_a accepts on its second call within one run, so a
 *        duplicate registration that was not a no-op would compute a value instead. */
#include <string.h>

#include "cqe.h"

static int mf_a_calls_i64;

static void mf_mul(const cqe_val *args, cqe_val *out, unsigned long long plus) {
  unsigned long long p = args[0].w[0] * args[1].w[0] + plus;
  out->w[0] |= p;
}

static int mf_a(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  (void)nargs;
  if (strcmp(t->w, "i8") == 0) {
    mf_mul(args, out, 0);
    return 0;
  }
  if (strcmp(t->w, "i64") == 0 && ++mf_a_calls_i64 > 1) {
    mf_mul(args, out, 0);
    return 0;
  }
  for (unsigned i = 0; i < out->nw; ++i)
    out->w[i] = ~0ull;
  return CQE_OP_NOT_MINE;
}

static int mf_b(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  (void)nargs;
  if (strcmp(t->w, "i16") == 0) {
    cqe_fail("multifam: mf_b rejects i16");
    return -1;
  }
  if (strcmp(t->w, "i32") != 0)
    return CQE_OP_NOT_MINE;
  mf_mul(args, out, 0);
  return 0;
}

static int mf_c(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  (void)nargs;
  if (strcmp(t->w, "i64") == 0)
    return CQE_OP_NOT_MINE;
  mf_mul(args, out, 1); /* off by one: visible if mf_c ever runs for i8, i16 or i32 */
  return 0;
}

__attribute__((constructor)) static void mf_register(void) {
  cqe_register_op("mul", mf_a);
  cqe_register_op("mul", mf_b);
  cqe_register_op("mul", mf_a);
  cqe_register_op("mul", mf_c);
}
