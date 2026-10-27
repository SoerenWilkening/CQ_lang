/* Test-only template family for tests/chk-core (never in checker/rt). Registers two handlers for
 * "add": the first accepts only i8 and declines (CQE_OP_NOT_MINE) every other width, the second
 * takes every width, so a call exercises several handlers per op. */
#include <string.h>

#include "cqe.h"

static int tf_add(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  if (nargs != 2)
    return -1;
  unsigned __int128 carry = 0;
  for (unsigned i = 0; i < out->nw; ++i) {
    unsigned long long a = i < args[0].nw ? args[0].w[i] : 0, b = i < args[1].nw ? args[1].w[i] : 0;
    unsigned __int128 s = (unsigned __int128)a + b + carry;
    out->w[i] = (unsigned long long)s;
    carry = s >> 64;
  }
  (void)t;
  return 0;
}
static int tf_add_i8(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  if (strcmp(t->w, "i8") != 0)
    return 1;
  return tf_add(t, args, nargs, out);
}
__attribute__((constructor)) static void tf_register(void) {
  cqe_register_op("add", tf_add_i8);
  cqe_register_op("add", tf_add);
}
