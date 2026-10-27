/* Stub (cq-w0-scaffold). Every function of cqe.h fails with "cq: unimplemented: chk-core: <function>".
 * Ownership passes to cq-w0-chk-core. */
#include <stdio.h>
#include <stdlib.h>

#include "cqe.h"

static _Noreturn void cqe_unimplemented_(const char *what) {
  fprintf(stderr, "cq: unimplemented: chk-core: %s\n", what);
  exit(1);
}

int cqe_parse_template(const char *sym, cqe_tname *out) { (void)sym; (void)out; cqe_unimplemented_("cqe_parse_template"); }
void cqe_register_op(const char *op, cqe_op_fn fn) { (void)op; (void)fn; cqe_unimplemented_("cqe_register_op"); }
int32_t cqe_new_rail(const char *w, const cqe_val *init, int known) { (void)w; (void)init; (void)known; cqe_unimplemented_("cqe_new_rail"); }
const cqe_val *cqe_rail(int32_t h) { (void)h; cqe_unimplemented_("cqe_rail"); }
void cqe_xor_into(int32_t h, const cqe_val *v) { (void)h; (void)v; cqe_unimplemented_("cqe_xor_into"); }
void cqe_set_known(int32_t h, int known) { (void)h; (void)known; cqe_unimplemented_("cqe_set_known"); }
void cqe_log(const char *json_object) { (void)json_object; cqe_unimplemented_("cqe_log"); }
void cqe_fail(const char *fmt, ...) { (void)fmt; cqe_unimplemented_("cqe_fail"); }
