/* Test-local stand-in for the checker core (cq-w0-tmpl-int). Only what a template family calls:
 * cqe_register_op records the handlers, cqe_fail counts violations. The real core is chk-core's. */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "fake_cqe.h"

fake_reg_t fake_regs[FAKE_MAX_REGS];
int fake_nregs;
int fake_fail_count;
char fake_fail_last[512];

void cqe_register_op(const char *op, cqe_op_fn fn) {
  if (fake_nregs == FAKE_MAX_REGS) { fprintf(stderr, "fake_cqe: registry full\n"); exit(2); }
  fake_regs[fake_nregs].op = op;
  fake_regs[fake_nregs].fn = fn;
  ++fake_nregs;
}

cqe_op_fn fake_lookup(const char *op) {
  for (int i = 0; i < fake_nregs; ++i)
    if (!strcmp(fake_regs[i].op, op)) return fake_regs[i].fn;
  return NULL;
}

void cqe_fail(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(fake_fail_last, sizeof fake_fail_last, fmt, ap);
  va_end(ap);
  ++fake_fail_count;
}

void cqe_log(const char *json_object) { (void)json_object; }

static _Noreturn void not_here_(const char *f) {
  fprintf(stderr, "fake_cqe: a template family called %s\n", f);
  exit(2);
}
int cqe_parse_template(const char *sym, cqe_tname *out) { (void)sym; (void)out; not_here_("cqe_parse_template"); }
int32_t cqe_new_rail(const char *w, const cqe_val *init, int known) { (void)w; (void)init; (void)known; not_here_("cqe_new_rail"); }
const cqe_val *cqe_rail(int32_t h) { (void)h; not_here_("cqe_rail"); }
void cqe_xor_into(int32_t h, const cqe_val *v) { (void)h; (void)v; not_here_("cqe_xor_into"); }
void cqe_set_known(int32_t h, int known) { (void)h; (void)known; not_here_("cqe_set_known"); }
