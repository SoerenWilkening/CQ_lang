/* Test-only stand-in for the chk-core registry (cq-arch M1 semantics): several handlers per op
 * name in registration order; 0 handled, CQE_OP_NOT_MINE (1) declined, -1 malformed after
 * cqe_fail. Only what tmpl_fenv.c calls is provided; the rest aborts. */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

#define MAXREG 64
static struct { char op[24]; cqe_op_fn fn; } reg[MAXREG];
static int nreg;
int mock_fail_count;

void cqe_register_op(const char *op, cqe_op_fn fn) {
  if (nreg == MAXREG) abort();
  snprintf(reg[nreg].op, sizeof reg[nreg].op, "%s", op);
  reg[nreg++].fn = fn;
}
void cqe_fail(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  fprintf(stderr, "cqe_fail: ");
  vfprintf(stderr, fmt, ap);
  fprintf(stderr, "\n");
  va_end(ap);
  mock_fail_count++;
}
/* 2 when no handler is registered under op; else the rc of the first non-declining handler, or 1 */
int mock_dispatch(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  int found = 0;
  for (int i = 0; i < nreg; ++i)
    if (!strcmp(reg[i].op, t->op)) {
      found = 1;
      int rc = reg[i].fn(t, args, nargs, out);
      if (rc != 1) return rc;
    }
  return found ? 1 : 2;
}
int mock_registered(const char *op) {
  for (int i = 0; i < nreg; ++i)
    if (!strcmp(reg[i].op, op)) return 1;
  return 0;
}
int cqe_parse_template(const char *s, cqe_tname *o) { (void)s; (void)o; abort(); }
int32_t cqe_new_rail(const char *w, const cqe_val *v, int k) { (void)w; (void)v; (void)k; abort(); }
const cqe_val *cqe_rail(int32_t h) { (void)h; abort(); }
void cqe_xor_into(int32_t h, const cqe_val *v) { (void)h; (void)v; abort(); }
void cqe_set_known(int32_t h, int k) { (void)h; (void)k; abort(); }
void cqe_log(const char *j) { (void)j; abort(); }
